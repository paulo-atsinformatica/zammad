<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ActiveJobLockCleanupJob < ApplicationJob
  include HasActiveJobLock

  def perform(diff = 1.day)
    ::ActiveJobLock.where(created_at: ...diff.ago).destroy_all
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ActiveJobLockCleanupJob < ApplicationJob
  include HasActiveJobLock

  def perform(diff = 1.day)
    ::ActiveJobLock.where(created_at: ...diff.ago).destroy_all
  end
end
>>>>>>> upstream/develop
