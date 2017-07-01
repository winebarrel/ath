class Ath::Query
  def initialize(shell:, query:, detach: false)
    @shell = shell
    @query = query
    @detach = detach
  end

  def run
    query_execution_id = @shell.driver.start_query_execution(
      query_string: @query,
      database: @shell.database,
      output_location: @shell.options.fetch(:output_location)
    ).query_execution_id

    if @detach
      return "QueryExecution #{query_execution_id}"
    end

    abort_waiting = false
    orig_handler = trap(:INT, proc { abort_waiting = true })
    query_execution = nil

    begin
      until abort_waiting
        query_execution = @shell.driver.get_query_execution(query_execution_id: query_execution_id)

        if query_execution.status.completion_date_time
          break
        end

        sleep 1
      end
    ensure
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
