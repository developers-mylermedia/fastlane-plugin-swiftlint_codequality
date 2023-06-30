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
                                      type: String)
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
