# frozen_string_literal: true

require 'meilisearch/http_request'
require 'timeout'

module MeiliSearch
  class Task < HTTPRequest
    ALLOWED_PARAMS = [
      :limit, :from, :index_uids, :types, :statuses, :uids, :canceled_by,
      :before_enqueued_at, :after_enqueued_at, :before_started_at, :after_started_at,
      :before_finished_at, :after_finished_at
    ].freeze

    def task_list(options = {})
      http_get '/tasks/', Utils.parse_query(options, ALLOWED_PARAMS)
    end

    def task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def index_tasks(index_uid)
      http_get '/tasks', { indexUids: [index_uid].flatten.join(',') }
    end

    def index_task(task_uid)
      http_get "/tasks/#{task_uid}"
    end

    def wait_for_task(task_uid, timeout_in_ms = 5000, interval_in_ms = 50)
      Timeout.timeout(timeout_in_ms.to_f / 1000) do
        loop do
          task = task(task_uid)
          return task if achieved_task?(task)

          sleep interval_in_ms.to_f / 1000
        end
      end
    rescue Timeout::Error
      raise MeiliSearch::TimeoutError
    end

    private

    def achieved_task?(task)
      task['status'] != 'enqueued' && task['status'] != 'processing'
    end
  end
end
