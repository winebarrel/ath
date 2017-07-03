class Ath::Query
  def initialize(shell:, query:, detach: false)
    @shell = shell
    @query = query
    @detach = detach
  end

  def run
    query_execution_id = @shell.driver.start_query_execution(query_string: @query).query_execution_id

    if @detach
      return "QueryExecution #{query_execution_id}"
    end

    abort_waiting = false
    orig_handler = trap(:INT, proc { abort_waiting = true })
    query_execution = nil
    running_progressbar = nil

    begin
      if @shell.options[:progress]
        running_progressbar = ProgressBar.create(title: 'Running', total: nil, output: $stderr)
      end

      until abort_waiting
        query_execution = @shell.driver.get_query_execution(query_execution_id: query_execution_id)

        if query_execution.status.completion_date_time
          break
        end

        running_progressbar.increment if running_progressbar
        sleep 1
      end
    ensure
      running_progressbar.clear if running_progressbar
      trap(:INT, orig_handler)
    end

    if abort_waiting
      return "QueryExecution #{query_execution_id}: Detach query"
    end

    if query_execution.status.state == 'SUCCEEDED'
      @shell.driver.get_query_execution_result(query_execution_id: query_execution_id)
    else
      "QueryExecution #{query_execution_id}: #{query_execution.status.state_change_reason}"
    end
  end
end
