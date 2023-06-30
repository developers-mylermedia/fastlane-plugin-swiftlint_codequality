require 'fastlane/action'
require_relative '../helper/swiftlint_codequality_helper'

module Fastlane
  module Actions
    class SwiftlintCodequalityAction < Action
      def self.run(params)
        UI.message("Parsing SwiftLint report at #{params[:path]}")

        pwd = Fastlane::Actions.sh("pwd", log: false).strip

        report = File.open(params[:path])
        result = report
                 .each
                 .select { |l| l.include?("Warning Threshold Violation") == false }
                 .map { |line| self.line_to_code_climate_object(line, params[:prefix], pwd) }
                 .to_a

        IO.write(params[:output], result.to_json)

        UI.success("🚀 Generated Code Quality report at #{params[:output]} 🚀")

        handle_result(result, params[:fail_build_conditions])
      end

      def self.line_to_code_climate_object(line, prefix, pwd)
        lintedLine = line.match(/(.*\.swift):(\d+):\d+:\s*(.*)/)
        if lintedLine.nil?
          return
        end
        filename, start, reason = lintedLine.captures

        # example: error: Type Name Violation: Type name should only contain alphanumeric characters: 'FILE' (type_name)

        issue_type, failure_type, description, _rule = reason.match(/(.*?):?\s(.*?):\s(.*)\((.*)\)/).captures

        case issue_type
        when 'error'
          severity = Severity::CRITICAL
        when 'warning'
          severity = Severity::MINOR
        else
          severity = Severity::INFO
        end

        {
          type: "issue",
          check_name: failure_type.strip,
          description: description.strip,
          fingerprint: Digest::MD5.hexdigest(line),
          severity: severity,
          location: {
            path: prefix + filename.sub(pwd, ''),
            lines: {
              begin: start.to_i,
              end: start.to_i
            }
          }
        }
      end

      def self.handle_result(result, fail_build_conditions)
        critical_limit = fail_build_conditions.fetch(Severity::CRITICAL.to_sym, 0)
        minor_limit = fail_build_conditions.fetch(Severity::MINOR.to_sym, 0)
        info_limit = fail_build_conditions.fetch(Severity::INFO.to_sym, 0)

        critical_count = result.select { |issue| issue[:severity] == Severity::CRITICAL }.length
        minor_count = result.select { |issue| issue[:severity] == Severity::MINOR }.length
        info_count = result.select { |issue| issue[:severity] == Severity::INFO }.length

        UI.important("")
        violations = false
        if critical_count > critical_limit
          UI.important("Critical issue limit (#{critical_limit}) exceeded: #{critical_count}")
          violations = true
        end
        if minor_count > minor_limit
          UI.important("Minor issue limit (#{minor_limit}) exceeded: #{minor_count}")
          violations = true
        end
        if info_count > info_limit
          UI.important("Info issue limit (#{info_limit}) exceeded: #{info_count}")
          violations = true
        end

        UI.important("")

        UI.user_error!("Severity limits where exceeded.") if violations
      end

      def self.description
        "Converts SwiftLint reports into GitLab support CodeQuality reports"
      end

      def self.authors
        ["madsbogeskov"]
      end

      def self.details
        "Converts SwiftLint reports into GitLab support CodeQuality reports"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                  env_name: "SWIFTLINT_CODEQUALITY_PATH",
                               description: "The path to the SwiftLint results file",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :output,
                                  env_name: "SWIFTLINT_CODEQUALITY_OUTPUT",
                               description: "The path to the generated output report",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :prefix,
                                  env_name: "SWIFTLINT_CODEQUALITY_PREFIX_PATH",
                               description: "Used to prefix the path of a file. Usefull in e.g. React Native projects where the iOS project is in a subfolder",
                                  optional: true,
                             default_value: '',
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :fail_build_conditions,
                                  env_name: "SWIFTLINT_CODEQUALITY_FAIL_BUILD_CONDITIONS",
                               description: "A hash with severities and their limits, that if exceeded should result in an exception. Supported severities: critical, minor and info",
                                 is_string: false,
                             default_value: {},
                                  optional: true)
        ]
      end

      def self.is_supported?(platform)
        true
      end

      class Severity
        CRITICAL = "critical".freeze
        MINOR = "minor".freeze
        INFO = "info".freeze
      end
    end
  end
end
