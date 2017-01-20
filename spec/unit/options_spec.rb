require 'spec_helper'

describe 'Options' do
  describe '.get_options' do
    describe 'pass in configuration file' do
      it 'adds config_file to options hash' do
        options = Options.get_options(['-c /tmp/config'])
        expect(options[:config_file]).to eq('/tmp/config')
      end
    end
    
    describe 'pass in help option' do
      it 'displays help and exits the program' do
        expect{ Options.get_options(['-h']) }.to raise_error SystemExit
      end
    end
  end
end