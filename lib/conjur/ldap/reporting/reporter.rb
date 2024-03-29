module Conjur::Ldap
  module Reporting
    class Reporter
      include Conjur::Ldap::Logging

      attr_accessor :io


      def output_format
        @output_format ||= :json
      end

      def output_format= fmt
        unless [:text, :json].include? fmt
          raise "output_format must be :text or :json (got '#{fmt}'"
        end
        @output_format = fmt
      end

      def initialize options={}
        @reports = []
        if options[:disable_reports]
          @io = nil
        else
          @io = options[:io] || $stdout
        end
      end

      def to_json
        as_json.to_json
      end

      def as_json
        {actions: actions}
      end

      # return a snapshot of reports
      def reports
        @reports.dup
      end

      def actions
        @reports.map(&:as_json)
      end

      def report tag, extras = {}
        report = Report.new tag, extras
        result = nil
        begin
          (yield if block_given?).tap{ report.succeed! }
        rescue => ex
          logger.error "error in action for #{tag}: #{ex}\n\t#{ex.backtrace.join("\n\t")}"
          report.fail! ex
          nil
        ensure
          issue_report report
        end
      end

      def issue_report report
        output = case output_format
          when :json then
            report.to_json
          when :text then
            report.format
          else
            raise 'Unreachable'
        end
        io && io.puts(output)
      end

      class Report

        def initialize tag, extras
          @tag = tag
          @extras = extras || {}
          @extras[:result] = :pending
        end

        attr_reader :tag

        def format
          "#{@tag}: #{format_extras}"
        end

        def format_extras
          # Sort to make the output reproducible
          @extras.keys.sort.collect { |k| "#{k}=#{@extras[k]}" }.join ", "
        end

        def extras
          @extras ||= {}
        end

        def succeed!
          extras[:result] = :success
        end

        def fail! ex
          extras[:result] = :failure
          extras[:error] = ex.to_s
        end

        def failed?
          extras[:result] == :failure
        end

        def succeeded?
          extras[:result] == :success
        end

        def as_json
          {tag: tag}.merge(extras)
        end

        def to_json
          as_json.to_json
        end
      end

    end
  end
end