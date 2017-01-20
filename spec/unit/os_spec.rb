require 'spec_helper'

describe 'OS' do
  describe '.command' do
    describe 'when OS is Windows' do
      it 'returns Windows command runner' do
        allow(OS).to receive(:windows?).and_return(true)
        allow(OS).to receive(:linux?).and_return(false)
        allow(OS).to receive(:unix?).and_return(false)
        allow(OS).to receive(:mac?).and_return(false)
        
        cmd = OS.command
        expect(cmd).to be_a(WindowsCommand)
      end
    end
    
    describe 'when OS is Linux' do
      it 'returns Linux command runner' do
        allow(OS).to receive(:windows?).and_return(false)
        allow(OS).to receive(:linux?).and_return(true)
        allow(OS).to receive(:unix?).and_return(false)
        allow(OS).to receive(:mac?).and_return(false)

        cmd = OS.command
        expect(cmd).to be_a(LinuxCommand)
      end
    end
  end
end