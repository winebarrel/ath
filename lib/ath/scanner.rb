class Ath::Scanner
  def initialize(shell:)
    @shell = shell
    @buf = ''
  end

  def scan(line)
    ss = StringScanner.new(line)

    if self.empty? and (tok = ss.scan %r{/\w+(?:\s+.*)?\z})
      cmd, arg = tok.split(/\s+/, 2)
      cmd.slice!(0)
      arg.strip! if arg
      yield(Ath::Command.new(shell: @shell, command: cmd, arg: arg))
    end

    until ss.eos?
      @buf << ' '

      if (tok = ss.scan %r{[^'"`;&]+})
        @buf << tok
      elsif (tok = ss.scan /`(?:``|[^`])*`/)
        @buf << tok
      elsif (tok = ss.scan /'(?:''|[^'])*'/)
        @buf << tok
      elsif (tok = ss.scan /"(?:""|[^"])*"/)
        @buf << tok
      elsif (tok = ss.scan /(?:[;&])/)
        query = @buf.strip
        @buf.clear
        raise Ath::Error, 'No query specified' if query.empty?
        yield(Ath::Query.new(shell: @shell, query: query, detach: (tok == '&')))
      else
        raise Ath::Error, 'You have an error in your HiveQL syntax'
      end
    end

    @buf.strip!
  end

  def empty?
    @buf.empty?
  end
end
