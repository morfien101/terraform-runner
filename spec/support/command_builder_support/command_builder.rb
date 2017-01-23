def create_CommandBuilder(action,module_updates,config_file,logger)
  cmd = CommandBuilder.new(action,module_updates,config_file,logger)
  allow(cmd).to receive(:terraform_bin).and_return('/usr/bin/terraform')
  return cmd
end

def new_config()
  return ConfigFile.new('spec/mockdir/scripts/configs/tf_mock.json', dummy_logger)
end
