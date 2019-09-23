describe Fastlane::Actions::SwiftlintCodequalityAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The swiftlint_codequality plugin is working!")

      Fastlane::Actions::SwiftlintCodequalityAction.run(nil)
    end
  end
end
