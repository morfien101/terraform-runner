DATA=<<-EOF
{
  	"environment": "Running Environment",
	  "tf_file_path":"/scripts/testdir",
		"variable_path":"/scripts/testdir",
		"variable_files":["vars1.tfvars","vars2.tfvars"],
		"inline_variables":{
		  "aws_ssh_key_path":"${ENV[\'aws_ssh_key_path\']}",
		  "aws_ssh_key_name": "myawskey"
		 },
		"state_file":{
		  "type":"s3",
		  "config": {
		    "region":"eu-west-1",
		    "bucket":"terraform-bucket",
		    "key":"path/to/terraform.tfstate"
		  }
		},
	"custom_args":["-parallelism=10"]
}
EOF

def setup_dir_io
  allow(Dir).to receive(:pwd).and_return('/terraform-runner')
  allow(IO).to receive(:read).with('/terraform-runner/scripts/config/test.json').and_return(DATA)
end

def create_CommandBuilder(action,module_updates,config_file)
  cmd = CommandBuilder.new(action,module_updates,config_file)
  allow(cmd).to receive(:terraform_bin).and_return('/usr/bin/terraform')
  return cmd
end
