class Ath::CLI
  def initialize(argv:)
    @argv = argv
  end

  def parse_options
    options = {
      database: 'default',
      output_location: ENV['ATH_OUTPUT_LOCATION'],
      pager: ENV['ATH_PAGER'],
      debug: false,
    }

    query = nil
    query_file = nil

    @argv.options do |opt|
      aws_opts = {}
      creds_opts = {}

      begin
        opt.on('-p', '--profile PROFILE_NAME')  {|v| creds_opts[:profile_name]    = v    }
        opt.on(''  , '--credentials-path PATH') {|v| creds_opts[:path]            = v    }
        opt.on('-k', '--access-key ACCESS_KEY') {|v| aws_opts[:access_key]        = v    }
        opt.on('-s', '--secret-key SECRET_KEY') {|v| aws_opts[:secret_access_key] = v    }
        opt.on('-r', '--region REGION')         {|v| aws_opts[:region]            = v    }
        opt.on(''  , '--output-location S3URI') {|v| options[:output_location]    = v    }
        opt.on('-d', '--database DATABASE')     {|v| options[:database]           = v    }
        opt.on('-e', '--execute QUERY')         {|v| query                        = v    }
        opt.on('-f', '--file QUERY_FILE')       {|v| query_file                   = v    }
        opt.on('',   '--pager PAGER')           {|v| options[:pager]              = v    }
        opt.on('',   '--[no-]progress')         {|v| options[:progress]           = v    }
        opt.on(''  , '--debug')                 {    options[:debug]              = true }
        opt.parse!

        unless options[:output_location]
          raise Ath::Error, '"--output-location" or ATH_OUTPUT_LOCATION is required'
        end

        if not creds_opts.empty?
          creds = Aws::SharedCredentials.new(credentials_opts)
          aws_opts[:credentials] = creds
        end

        Aws.config.update(aws_opts)
      rescue Ath::Error, OptionParser::ParseError => e
        $stderr.puts("[ERROR] #{e.message}")
        exit 1
      rescue => e
        $stderr.puts("[ERROR] #{e.message}")
        puts "\t" + e.backtrace.join("\n\t")
        exit 1
      end
    end

    if options[:debug]
      Aws.config.update(
        http_wire_trace: true,
        logger: Logger.new($stdout).tap {|l| l.level = Logger::DEBUG },
      )
    end

    begin
      options[:output_location] = ERB.new(options[:output_location]).result
    rescue => e
      $stderr.puts("[ERROR] Eval output-location failed: #{e.message}")
      exit 1
    end

    return [options, query, query_file]
  end

  def main
    options, query, query_file = parse_options

    begin
      shell = Ath::Shell.new(
        output_location: options.delete(:output_location),
        database: options.delete(:database),
        pager: options.delete(:pager),
        options: options)

      if query_file
        if query_file == '-'
          query = $stdin.read
        else
          query = File.read(query_file)
        end
      end

      if query
        options[:progress] = false unless options.has_key?(:progress)
        query.strip!
        query << ';' if query !~ /[;&]\z/
        shell.oneshot(query)
      else
        options[:progress] = true unless options.has_key?(:progress)
        shell.start
      end
    rescue Interrupt
      # nothing to do
    rescue => e
      if options[:debug]
        raise e
      else
        $stderr.puts("[ERROR] #{[e.message, e.backtrace.first].join("\n\t")}")
        exit 1
      end
    end
  end
end
