class Ath::Driver
  attr_accessor :database

  def initialize(athena:, s3:, output_location:, database:)
    @athena = athena
    @s3 = s3
    @output_location = output_location
    @database = database
  end

  def get_query_execution(query_execution_id:)
    @athena.get_query_execution(query_execution_id: query_execution_id).query_execution
  end

  def list_query_executions
    query_execution_ids = @athena.list_query_executions.each_page.flat_map(&:query_execution_ids)
    @athena.batch_get_query_execution(query_execution_ids: query_execution_ids.slice(0, 50)).query_executions
  end

  def get_query_execution_result(query_execution_id:)
    bucket, key = get_query_execution_result_output_location(query_execution_id: query_execution_id)
    tmp = Tempfile.create('ath')

    if block_given?
      @s3.get_object(bucket: bucket, key: key) do |chunk|
        yield(chunk)
        tmp.write(chunk)
      end
    else
      @s3.get_object(bucket: bucket, key: key) do |chunk|
        tmp.write(chunk)
      end
    end

    tmp.flush
    tmp
  end

  def head_query_execution_result(query_execution_id:)
    bucket, key = get_query_execution_result_output_location(query_execution_id: query_execution_id)
    @s3.head_object(bucket: bucket, key: key)
  end

  def get_query_execution_result_output_location(query_execution_id:)
    query_execution = @athena.get_query_execution(query_execution_id: query_execution_id).query_execution
    output_location = query_execution.result_configuration.output_location
    output_location.sub(%r{\As3://}, '').split('/', 2)
  end

  def start_query_execution(query_string:)
    @athena.start_query_execution(
      query_string: query_string,
      query_execution_context: {database: @database},
      result_configuration: {output_location: @output_location})
  end

  def stop_query_execution(query_execution_id:)
    @athena.stop_query_execution(query_execution_id: query_execution_id)
  end

  def output_location
    @output_location
  end

  def output_location=(v)
    @output_location = v
  end

  def region
    @athena.config.region
  end

  def region=(v)
    @athena.config.region = v
    @athena.config.sigv4_region = v
    @athena.config.endpoint = Aws::EndpointProvider.resolve(v, 'athena')
  end
end
