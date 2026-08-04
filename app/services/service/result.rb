# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Result
  attr_reader :success, :data, :error

  def initialize(success:, data: nil, error: nil, **options)
    @success = success
    @data = data
    @error = error
    @options = options

    # Define accessor methods for all options
    @options.each do |key, value|
      define_singleton_method(key) { value }
    end
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def [](key)
    case key
    when :success then @success
    when :data then @data
    when :error then @error
    else
      @options[key]
    end
  end

  # Allow method access to options - return nil if not found
  def method_missing(method_name, *args, &block)
    return @options[method_name] if @options.key?(method_name)
    return nil # Return nil for unknown options instead of raising error
  end

  def respond_to_missing?(method_name, include_private = false)
    true # Always respond to allow nil returns for missing options
  end
end
