<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessDelayedJobs < BaseDelayedJobs

      def self.pre_launch
        start_time = Time.zone.now

        CleanupAction.cleanup_delayed_jobs(start_time, queues:)
        ImportJob.cleanup_import_jobs(start_time)
      end

      def self.queues
        [:default].freeze
      end
    end
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class BackgroundServices
  class Service
    class ProcessDelayedJobs < BaseDelayedJobs

      def self.pre_launch
        start_time = super

        ImportJob.cleanup_import_jobs(start_time)
      end

      def self.queues
        [:default].freeze
      end
    end
  end
end
>>>>>>> upstream/develop
