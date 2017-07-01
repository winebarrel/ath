class Ath::Driver
  def initialize(athena:, s3:)
    @athena = athena
    @s3 = s3
  end

  def get_query_execution(query_execution_id:)

    @athena.get_query_execution(query_execution_id: query_execution_id).query_execution
  end

  def list_query_executions
    query_execution_ids = @athena.list_query_executions.each_page.flat_map(&:query_execution_ids)
    @athena.batch_get_query_execution(query_execution_ids: query_execution_ids.slice(0, 50)).query_executions
  end

  def get_query_execution_result(query_execution_id:)
    query_execution = @athena.get_query_execution(query_execution_id: query_execution_id).query_execution
    output_location = query_execution.result_configuration.output_location
    bucket, key = output_location.sub(%r{\As3://}, '').split('/', 2)
    tmp = Tempfile.create('ath')

    @s3.get_object(bucket: bucket, key: key) do |chunk|
      tmp.write(chunk)
    end

    tmp.flush
    tmp
  end

  def start_query_execution(query_string:, database:, output_location:)
    @athena.start_query_execution(
      query_string: query_string,
      query_execution_context: {database: database},
      result_configuration: { output_location: output_location}
    )
  end

  def stop_query_execution(query_execution_id:)
    @athena.stop_query_execution(query_execution_id: query_execution_id)
  end
end
