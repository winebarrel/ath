class Ath::Command
  MAX_LIST_QUERY = 20

  def initialize(shell:, command:, arg: nil)
    @shell = shell
    @command = command
    @arg = arg
  end

  def run
    out = nil

    case @command
    when 'debug'
      if @arg == 'true' or @arg == 'false'
        @shell.options[:debug] = (@arg =~ /true/)
      else
        out = !!@shell.options.fetch(:debug)
      end
    when 'desc'
      if @arg
        query_execution = @shell.driver.get_query_execution(query_execution_id: @arg)
        out = JSON.pretty_generate(query_execution.to_h)
      else
        out = "Usage: /desc QUERY_EXECUTION_ID"
      end
    when 'help'
      out = usage
    when 'list'
      query_executions = @shell.driver.list_query_executions
      query_executions.sort_by! {|qe| qe.status.submission_date_time }.reverse!

      lines = query_executions.map do |qe|
        line = [
          qe.status.submission_date_time,
          qe.query_execution_id,
          qe.status.state,
        ]

        if qe.query.length > MAX_LIST_QUERY
          line << qe.query.slice(0, MAX_LIST_QUERY) + '..'
        else
          line << qe.query
        end

        line.join("\s")
      end

      if @arg
        lines = lines.slice(0, @arg.to_i)
      end

      out = lines.join("\n")
    when 'pager'
      if @arg
        @shell.pager = @arg
      else
        @shell.pager = nil
        out = "Using stdout"
      end
    when 'result'
      if @arg
        out = @shell.driver.get_query_execution_result(query_execution_id: @arg)
      else
        out = "Usage: /result QUERY_EXECUTION_ID"
      end
    when 'stop'
      if @arg
        @shell.driver.stop_query_execution(query_execution_id: @arg)
      else
        out = "Usage: /stop QUERY_EXECUTION_ID"
      end
    when 'use'
      if @arg
        @shell.database = @arg
      else
        out = "Usage: /use DATABASE"
      end
    else
      raise Ath::Error, "Unknown command: #{@command}"
    end

    out
  end

  private

  def usage
    <<-EOS
/debug true|false
/desc QUERY_EXECUTION_ID
/help
/list [NUM]
/pager PAGER
/result QUERY_EXECUTION_ID
/stop QUERY_EXECUTION_ID
/use DATABASE
    EOS
  end
end
