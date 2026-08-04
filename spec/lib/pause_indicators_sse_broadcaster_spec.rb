# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PauseIndicatorsSseBroadcaster do
  # O módulo mantém estado de classe (@queues, @listener_thread, @heartbeat_thread).
  # O bloco around garante isolamento completo entre exemplos.
  around do |example|
    described_class.instance_variable_get(:@queues).each { |q| q.close rescue nil }
    described_class.instance_variable_set(:@queues, [])
    described_class.instance_variable_set(:@listener_thread, nil)
    described_class.instance_variable_set(:@heartbeat_thread, nil)
    example.run
  ensure
    described_class.instance_variable_get(:@queues).each { |q| q.close rescue nil }
    described_class.instance_variable_set(:@queues, [])
    described_class.instance_variable_set(:@listener_thread, nil)
    described_class.instance_variable_set(:@heartbeat_thread, nil)
  end

  let(:queues) { described_class.instance_variable_get(:@queues) }

  # ---------------------------------------------------------------------------
  # .subscribe
  # ---------------------------------------------------------------------------
  describe '.subscribe' do
    before do
      allow(described_class).to receive(:ensure_listener_running)
      allow(described_class).to receive(:ensure_heartbeat_running)
    end

    it 'returns a Queue' do
      expect(described_class.subscribe).to be_a(Queue)
    end

    it 'registers the returned queue' do
      queue = described_class.subscribe
      expect(queues).to include(queue)
    end

    it 'starts listener and heartbeat threads' do
      described_class.subscribe
      expect(described_class).to have_received(:ensure_listener_running)
      expect(described_class).to have_received(:ensure_heartbeat_running)
    end

    it 'each call registers a distinct queue' do
      q1 = described_class.subscribe
      q2 = described_class.subscribe
      expect(q1).not_to be(q2)
      expect(queues).to include(q1, q2)
    end
  end

  # ---------------------------------------------------------------------------
  # .unsubscribe
  # ---------------------------------------------------------------------------
  describe '.unsubscribe' do
    before do
      allow(described_class).to receive(:ensure_listener_running)
      allow(described_class).to receive(:ensure_heartbeat_running)
    end

    it 'removes the queue from the registry' do
      queue = described_class.subscribe
      described_class.unsubscribe(queue)
      expect(queues).not_to include(queue)
    end

    it 'closes the queue' do
      queue = described_class.subscribe
      described_class.unsubscribe(queue)
      expect(queue).to be_closed
    end

    it 'tolerates nil without raising' do
      expect { described_class.unsubscribe(nil) }.not_to raise_error
    end

    it 'tolerates already-closed queue without raising' do
      queue = described_class.subscribe
      queue.close
      expect { described_class.unsubscribe(queue) }.not_to raise_error
    end
  end

  # ---------------------------------------------------------------------------
  # .fan_out
  # ---------------------------------------------------------------------------
  describe '.fan_out' do
    it 'pushes :refresh to all open queues by default' do
      q1 = Queue.new
      q2 = Queue.new
      queues.push(q1, q2)

      described_class.fan_out

      expect(q1.pop(timeout: 0.1)).to eq(:refresh)
      expect(q2.pop(timeout: 0.1)).to eq(:refresh)
    end

    it 'pushes the given message to all open queues' do
      q = Queue.new
      queues << q

      described_class.fan_out(:heartbeat)

      expect(q.pop(timeout: 0.1)).to eq(:heartbeat)
    end

    it 'removes closed queues and does not push to them' do
      q_open   = Queue.new
      q_closed = Queue.new.tap(&:close)
      queues.push(q_open, q_closed)

      expect { described_class.fan_out }.not_to raise_error

      expect(queues).to     include(q_open)
      expect(queues).not_to include(q_closed)
    end

    it 'does nothing when no queues registered' do
      expect { described_class.fan_out }.not_to raise_error
    end
  end

  # ---------------------------------------------------------------------------
  # listener_loop (private — testado via send)
  # ---------------------------------------------------------------------------
  describe 'listener_loop (private)' do
    let(:fake_redis) { instance_double(Zammad::Service::Redis, close: nil) }

    before do
      allow(described_class).to receive(:sleep)
      allow(Zammad::Service::Redis).to receive(:new).and_return(fake_redis)
    end

    context 'quando queues estão vazias ao iniciar' do
      it 'encerra imediatamente sem contatar Redis' do
        expect(Zammad::Service::Redis).not_to receive(:new)

        thread = Thread.new { described_class.send(:listener_loop) }
        thread.join(1)

        expect(thread.alive?).to be false
      end
    end

    context 'quando Redis está disponível' do
      it 'faz fan_out de :refresh ao receber mensagem do Redis' do
        q = Queue.new
        queues << q

        allow(fake_redis).to receive(:subscribe) do |_channel, &block|
          on = Object.new
          on.define_singleton_method(:message) { |&cb| @cb = cb }
          block.call(on)
          on.instance_variable_get(:@cb)&.call('channel', 'any')
          queues.clear # sem clientes → loop encerra após este bloco
        end

        thread = Thread.new { described_class.send(:listener_loop) }
        thread.join(2)

        expect(q.pop(timeout: 0.1)).to eq(:refresh)
      end

      it 'reseta consecutive_errors após conexão bem-sucedida' do
        q = Queue.new
        queues << q
        call_count = 0

        allow(Zammad::Service::Redis).to receive(:new) do
          call_count += 1
          fake_redis
        end

        allow(fake_redis).to receive(:subscribe) { queues.clear }

        Thread.new { described_class.send(:listener_loop) }.join(2)

        expect(call_count).to eq(1)
      end
    end

    context 'quando Redis falha repetidamente' do
      before do
        allow(Zammad::Service::Redis).to receive(:new)
          .and_raise(Redis::BaseConnectionError, 'connection refused')
      end

      it "encerra após #{described_class::MAX_RECONNECT_ATTEMPTS} tentativas consecutivas" do
        queues << Queue.new

        thread = Thread.new { described_class.send(:listener_loop) }
        thread.join(3)

        expect(thread.alive?).to be false
      end

      it 'limpa @listener_thread no ensure' do
        queues << Queue.new

        Thread.new { described_class.send(:listener_loop) }.join(3)

        expect(described_class.instance_variable_get(:@listener_thread)).to be_nil
      end

      it 'loga warning a cada falha e error ao parar' do
        queues << Queue.new
        max = described_class::MAX_RECONNECT_ATTEMPTS

        expect(Rails.logger).to receive(:warn).exactly(max).times
        expect(Rails.logger).to receive(:error).once

        Thread.new { described_class.send(:listener_loop) }.join(3)
      end

      it 'aplica backoff exponencial (sleep cresce com tentativas)' do
        queues << Queue.new
        delays = []
        allow(described_class).to receive(:sleep) { |d| delays << d }

        Thread.new { described_class.send(:listener_loop) }.join(3)

        # delays devem crescer até o cap de 30s
        expect(delays.first).to be <= delays.last
        expect(delays.max).to be <= 30
      end
    end

    context 'quando Redis falha e não há mais clientes' do
      it 'encerra sem atingir o limite de tentativas' do
        queues << Queue.new

        call_count = 0
        allow(Zammad::Service::Redis).to receive(:new) do
          call_count += 1
          queues.clear if call_count == 1
          raise Redis::BaseConnectionError, 'refused'
        end

        thread = Thread.new { described_class.send(:listener_loop) }
        thread.join(2)

        expect(thread.alive?).to be false
        expect(call_count).to be < described_class::MAX_RECONNECT_ATTEMPTS
      end
    end
  end

  # ---------------------------------------------------------------------------
  # heartbeat_loop (private — testado via send)
  # ---------------------------------------------------------------------------
  describe 'heartbeat_loop (private)' do
    before { allow(described_class).to receive(:sleep) }

    context 'quando queues estão vazias' do
      it 'encerra após o primeiro tick sem enviar heartbeat' do
        thread = Thread.new { described_class.send(:heartbeat_loop) }
        thread.join(1)

        expect(thread.alive?).to be false
      end

      it 'limpa @heartbeat_thread no ensure' do
        Thread.new { described_class.send(:heartbeat_loop) }.join(1)

        expect(described_class.instance_variable_get(:@heartbeat_thread)).to be_nil
      end
    end

    context 'quando há queues registradas' do
      it 'envia :heartbeat e encerra quando queue é fechada' do
        q = Queue.new
        queues << q

        received = []
        consumer = Thread.new do
          msg = q.pop
          received << msg
          q.close # sinaliza para o loop encerrar no próximo tick
        end

        thread = Thread.new { described_class.send(:heartbeat_loop) }
        consumer.join(2)
        thread.join(2)

        expect(received).to eq([:heartbeat])
      end

      it 'remove queues fechadas automaticamente' do
        q = Queue.new
        q.close
        queues << q

        thread = Thread.new { described_class.send(:heartbeat_loop) }
        thread.join(1)

        expect(queues).not_to include(q)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Integração: subscribe → fan_out → recebimento na fila
  # ---------------------------------------------------------------------------
  describe 'integração subscribe/unsubscribe/fan_out' do
    before do
      allow(described_class).to receive(:ensure_listener_running)
      allow(described_class).to receive(:ensure_heartbeat_running)
    end

    it 'entrega mensagem de fan_out à fila inscrita' do
      queue = described_class.subscribe
      described_class.fan_out(:refresh)
      expect(queue.pop(timeout: 0.1)).to eq(:refresh)
    end

    it 'não entrega mensagem a fila após unsubscribe' do
      queue = described_class.subscribe
      described_class.unsubscribe(queue)
      described_class.fan_out(:refresh)
      expect(queue.pop(timeout: 0.1)).to be_nil
    end

    it 'múltiplos inscritos recebem a mesma mensagem' do
      q1 = described_class.subscribe
      q2 = described_class.subscribe
      described_class.fan_out(:refresh)
      expect(q1.pop(timeout: 0.1)).to eq(:refresh)
      expect(q2.pop(timeout: 0.1)).to eq(:refresh)
    end
  end
end
