# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :searchindex do
    namespace :organization do
      desc 'Reindex all organizations (useful after adding custom fields)'
      task :reload, [:worker] => %i[zammad:searchindex:version_supported] do |_task, args|
        puts 'Reindexing organizations...'
        time_spent = Benchmark.realtime do
          Organization.search_index_reload(worker: args[:worker].to_i)
        end
        puts "Done in #{time_spent.to_i} seconds."
      end

      desc 'Refresh organization search index (apply pending changes)'
      task refresh: %i[zammad:searchindex:version_supported] do
        print 'Refreshing organization index... '
        SearchIndexBackend.refresh
        puts 'done.'
      end
    end
  end
end



