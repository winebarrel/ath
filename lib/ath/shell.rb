class Ath::Shell
  HISTORY_FILE = File.join(ENV.fetch('HOME', '.'), '.ath_history')
  HISTSIZE = 1000

  attr_reader :driver
  attr_reader :options
  attr_accessor :pager

  def initialize(athena: Aws::Athena::Client.new, s3: Aws::S3::Client.new, output_location:, database: nil, options: {})
    @driver = Ath::Driver.new(athena: athena, s3: s3, output_location: output_location, database: database)
    @options = options
    @scanner = Ath::Scanner.new(shell: self)
  end

  def start
    load_history

    while line = Readline.readline(prompt, true)
      execute_query(line)
    end
  ensure
    save_history
  end

  def oneshot(query)
    execute_query(query)
  end

  private

  def execute_query(line)
    begin
      execute_query0(line)
    rescue => e
      puts e.message

      if @options[:debug]
        puts e.backtrace.join("\n\t")
      end
    end
  end

  def execute_query0(line)
    @scanner.scan(line) do |cmd_or_query|
      out = nil

      case cmd_or_query
      when Ath::Command
        out = cmd_or_query.run
      when Ath::Query
        out = cmd_or_query.run
      else
        raise 'must not happen'
      end

      print_result(out)
    end
  end

  def prompt
    database = @driver.database || '(none)'

    if @scanner.empty?
      "#{database}> "
    else
      indent = "\s" * (database.length - 1)
      "#{indent}-> "
    end
  end

  def print_result(out)
    return if out.nil?

    if out.kind_of?(File)
      begin
        cmd = "cat #{out.path}"
        cmd << " | #{@pager}" if @pager
        system(cmd)

        begin
          out.seek(-1, IO::SEEK_END)
          puts if out.gets !~ /\n\z/
        rescue Errno::EINVAL
          puts
        end
      ensure
        out.close
      end
    else
      if @pager
        Tempfile.create('ath') do |f|
          f.puts out
          f.flush
          system("cat #{f.path} | #{@pager}")
        end
      else
        puts out
      end
    end
  end

  def load_history
    return unless File.exist?(HISTORY_FILE)

    open(HISTORY_FILE) do |f|
      f.each_line.map(&:strip).reject(&:empty?).each do |line|
        Readline::HISTORY.push(line)
      end
    end
  end

  def save_history
    history = Readline::HISTORY.map(&:strip).reject(&:empty?).reverse.uniq.reverse

    if history.length < HISTSIZE
      offset = history.length
    else
      offset = HISTSIZE
    end

    history = history.slice(-offset..-1) || []
    return if history.empty?

    open(HISTORY_FILE, 'wb') do |f|
      history.each {|l| f.puts l }
    end
  end
end
