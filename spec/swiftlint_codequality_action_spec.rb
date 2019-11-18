describe Fastlane::Actions::SwiftlintCodequalityAction do
  let(:fixtures_path) { File.expand_path("./spec/fixtures") }
  let(:fail_build_conditions) { { critical: 1000, minor: 1000, info: 1000 } }

  describe '#run' do
    it 'generates empty output if input is also empty' do
      path = fixtures_path + "/empty.txt"
      output = fixtures_path + "/empty.result.json"

      expect(Fastlane::UI).to receive(:message).with("Parsing SwiftLint report at #{path}")
      expect(Fastlane::UI).to receive(:success).with("🚀 Generated Code Quality report at #{output} 🚀")

      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: fail_build_conditions)

      result = File.read(output)
      expect(result).to eq("[]")
    end

    it 'generates an output if input is non empty' do
      path = fixtures_path + "/single.txt"
      output = fixtures_path + "/single.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: fail_build_conditions)

      result = File.read(output)
      expect(result).to eq(%q{[{"type":"issue","check_name":"Identifier Name Violation","description":"Variable name should be between 3 and 40 characters long: 'p'","fingerprint":"684722650e18611b41939c985095d204","severity":"critical","location":{"path":"/Project/File.swift","lines":{"begin":20,"end":20}}}]})
    end

    it 'outputs as many code climate objects as there are swiftlint issues' do
      path = fixtures_path + "/multiple.txt"
      output = fixtures_path + "/multiple.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: fail_build_conditions)

      input = File.foreach(path).count
      result = JSON.parse(File.read(output)).length
      expect(result).to eq(input)
    end

    it 'categories swiftlint issues into different severities' do
      path = fixtures_path + "/multiple.txt"
      output = fixtures_path + "/multiple.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: fail_build_conditions)

      result = JSON.parse(File.read(output))
      critical_count = result.select { |issue| issue["severity"] == Fastlane::Actions::SwiftlintCodequalityAction::Severity::CRITICAL }.length
      minor_count = result.select { |issue| issue["severity"] == Fastlane::Actions::SwiftlintCodequalityAction::Severity::MINOR }.length
      info_count = result.select { |issue| issue["severity"] == Fastlane::Actions::SwiftlintCodequalityAction::Severity::INFO }.length

      expect(critical_count).to eq(4)
      expect(minor_count).to eq(2)
      expect(info_count).to eq(2)
    end

    it 'raises an exception if the number of critical issues exceeds the maximum' do
      path = fixtures_path + "/multiple.txt"
      output = fixtures_path + "/multiple.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)
      expect(Fastlane::UI).to receive(:user_error!).with("Severity limits where exceeded.")

      conditions = fail_build_conditions
      conditions[:critical] = 0
      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: conditions)
    end

    it 'raises an exception if the number of minor issues exceeds the maximum' do
      path = fixtures_path + "/multiple.txt"
      output = fixtures_path + "/multiple.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)
      expect(Fastlane::UI).to receive(:user_error!).with("Severity limits where exceeded.")

      conditions = fail_build_conditions
      conditions[:minor] = 0
      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: conditions)
    end

    it 'raises an exception if the number of info issues exceeds the maximum' do
      path = fixtures_path + "/multiple.txt"
      output = fixtures_path + "/multiple.result.json"

      command = "pwd"
      command_result = "/Users/apple/projects"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)
      expect(Fastlane::UI).to receive(:user_error!).with("Severity limits where exceeded.")

      conditions = fail_build_conditions
      conditions[:info] = 0
      Fastlane::Actions::SwiftlintCodequalityAction.run(path: path, output: output, prefix: '', fail_build_conditions: conditions)
    end
  end

  describe 'swiftlint_codequality' do
    it 'default use case' do
      path = fixtures_path + "/empty.txt"
      output = fixtures_path + "/empty.result.json"

      Fastlane::FastFile.new.parse("lane :test do
        swiftlint_codequality(path: '#{path}', output: '#{output}')
      end").runner.execute(:test)

      result = File.read(output)
      expect(result).to eq("[]")
    end
  end
end
