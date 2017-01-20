require 'spec_helper'

describe 'CommandBuilder' do
  before(:each) do
    setup_dir_io
  end

  describe '#tf_state_file_cmd' do
    describe 'full terraform remote state command' do
      it 'return state file command' do
        cmd = create_CommandBuilder(nil,nil,'scripts/config/test.json')
        expect(cmd.tf_state_file_cmd).to eq('/usr/bin/terraform remote config -backend=s3 -backend-config="region=eu-west-1" -backend-config="bucket=terraform-bucket" -backend-config="key=path/to/terraform.tfstate"')
      end
    end
  end

  describe '#tf_action_cmd' do
    describe 'action plan' do
      it 'return full plan command' do
        ENV['aws_ssh_key_path'] = "sshkeypath"
        cmd = create_CommandBuilder('plan',nil,'scripts/config/test.json')
        expect(cmd.tf_action_cmd).to eq('/usr/bin/terraform plan -var aws_ssh_key_path=sshkeypath -var aws_ssh_key_name=myawskey -var-file="/terraform-runner/scripts/testdir/vars1.tfvars" -var-file="/terraform-runner/scripts/testdir/vars2.tfvars" -parallelism=10 -detailed-exitcode')
      end
    end

    describe 'action get' do
      it 'return full get command with true @module_updates' do
        cmd = create_CommandBuilder('get',true,'scripts/config/test.json')
        expect(cmd.tf_action_cmd).to eq('/usr/bin/terraform get -update')
      end

      it 'return full get command with false @module_updates' do
        cmd = create_CommandBuilder('get',false,'scripts/config/test.json')
        expect(cmd.tf_action_cmd).to eq('/usr/bin/terraform get')
      end
    end

    describe 'action destroy' do
      it 'return full destroy command with -force flag' do
        cmd = create_CommandBuilder('destroy',false,'scripts/config/test.json')
        expect(cmd.tf_action_cmd).to eq('/usr/bin/terraform destroy -var aws_ssh_key_path=sshkeypath -var aws_ssh_key_name=myawskey -var-file="/terraform-runner/scripts/testdir/vars1.tfvars" -var-file="/terraform-runner/scripts/testdir/vars2.tfvars" -parallelism=10 -force')
      end
    end
  end

end
