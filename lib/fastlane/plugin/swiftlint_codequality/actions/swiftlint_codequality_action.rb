require 'fastlane/action'
require_relative '../helper/swiftlint_codequality_helper'

module Fastlane
  module Actions
    class SwiftlintCodequalityAction < Action
      def self.run(params)
        UI.message("Parsing SwiftLint report at #{params[:path]}")

        pwd = `pwd`.strip

        result = File.open(params[:path])
            .each
            .select { |l| l.include?("Warning Threshold Violation") == false }
            .map { |line|
               filename, start, reason = line.match(/(.*\.swift):(\d+):\d+:\s*(.*)/).captures
  
               {
                :description => reason, 
                :fingerprint => Digest::MD5.hexdigest(line),
                :location => {
                  :path => "ios" + filename.sub(pwd, ''),
                  :lines => {
                    :begin => start.to_i
                  }
                }
              }
            }
            .to_a
            .to_json

        IO.write(params[:output], result)

        UI.success "🚀 Generated Code Quality report at #{params[:output]} 🚀"
      end

      def self.description
        "Converts SwiftLint reports into GitLab support CodeQuality reports"
      end

      def self.authors
        ["madsbogeskov"]
      end

      def self.return_value
        
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
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
