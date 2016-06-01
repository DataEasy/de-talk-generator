require 'rails_helper'

describe CoverService do
  describe '#publish_cover' do
    it 'should create' do
      talk = build(:talk)

      allow(FileUtils).to receive(:cp).with(instance_of(Pathname), instance_of(Pathname)).twice
      allow(FileUtils).to receive(:rm).with(instance_of(Pathname)).twice

      # Mocking Kernel functions
      expect(subject).to receive(:system).with(/sed -i/).and_return(true)
      expect(subject).to receive(:system).with(/inkscape/)
      expect(subject).to receive(:sleep).with(2)

      subject.publish_cover(talk)
    end
  end
end