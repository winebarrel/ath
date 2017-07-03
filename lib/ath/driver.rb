class Ath::Driver
  attr_accessor :database

  def initialize(athena:, s3:, output_location:, database:, options: {})
    @athena = athena
    @s3 = s3
    @output_location = output_location
    @database = database
    @options = options
  end

  def get_query_execution(query_execution_id:)
    @athena.get_query_execution(query_execution_id: query_execution_id).query_execution
  end

  def list_query_executions
    query_execution_ids = @athena.list_query_executions.each_page.flat_map(&:query_execution_ids)
    @athena.batch_get_query_execution(query_execution_ids: query_execution_ids.slice(0, 50)).query_executions
  end

  def get_query_execution_result(query_execution_id:)
    tmp = Tempfile.create('ath')
    bucket, key = get_query_execution_result_output_location(query_execution_id: query_execution_id)
    download_query_execution_result(bucket: bucket, key: key, file: tmp)
  end

  def save_query_execution_result(query_execution_id:, path:)
    bucket, key = get_query_execution_result_output_location(query_execution_id: query_execution_id)

    if File.directory?(path)
      path = File.join(path, File.basename(key))
    end

    open(path, 'wb') do |file|
      download_query_execution_result(bucket: bucket, key: key, file: file)
    end

    path
  end

  def download_query_execution_result(bucket:, key:, file:)
    head = @s3.head_object(bucket: bucket, key: key)

    if @options[:progress] and head.content_length >= 1024 ** 2
      download_progressbar = ProgressBar.create(title: 'Download', total: head.content_length, output: $stderr)

      begin
        @s3.get_object(bucket: bucket, key: key) do |chunk|
          file.write(chunk)

          begin
            download_progressbar.progress += chunk.length
          rescue ProgressBar::InvalidProgressError
            # nothing to do
          end
        end
      ensure
        download_progressbar.clear
      end
    else
      @s3.get_object(bucket: bucket, key: key) do |chunk|
        file.write(chunk)
      end
    end

    file.flush
    file
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
