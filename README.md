# What is the Terraform runner

The terraform-runner.rb script was written to over come some of the limitation of terraform.
It is used to deploy code to different environments. It is written in ruby and is designed to be able to work on windows, mac and linux.

*__You have to have the terraform binaries expanded on your computer and available in one of your PATH directories already__*.

The config files are written in json and describe the variables and files that need to be run. It will also download the current version of the terraform state file that is stored in S3 currently. This could technically be any supported backend remote state file but, has only beed tested with S3.

#### The process when running the script is as follows.  
1. Delete the directory "terraform-runner-working-dir" if it is already there.  
2. Create the directory "terraform-runner-working-dir".  
3. Copy the contents of the project specified in the json file to the working directory.  
4. Download a copy of the current remote terraform state file. It will be stored in "terraform-runner-working-dir/.terraform".  
5. Run the terraform command with the supplied action.  
6. Output the STDOUT from the terraform executable.  

This process was designed to work with tools like jenkins.

Due to limitiation in the windows supplied verison on ruby standard gems. The STDOUT of the terraform command will be shown only once the command has completed execution.
This is because of buffereing of STDOUT in C libaries which is vastly outside the scope of this artical.
However it will make the terraform runner look like it has frozen until the run is complete.

# What does the config file look like
Below is an example config file.  
__Example terraform runner file__
```javascript
{
	"environment": "AWS Training",
	"tf_file_path":"scripts/aws_training_vpc",
	"variable_path":"scripts/aws_training_vpc",
	"variable_files":["vpc.tfvars"],
	"inline_variables":{
		"aws_account_number":"${ENV['AWS_ACCOUNT_NUMBER']}"
	},
	"state_file":{
		"type":"s3",
		"config": {
			"region":"us-east-1",
			"bucket":"terraform-bucket",
			"key":"aws_training/vpc/terraform.tfstate"
		}
	},
	"custom_args":["-parallelism=10"]
}
```

We wil look at each section now.
* __environment__  
Used only for human information.
* __tf_file_path__  
The location of the .tf files relative to the terraform runner script.  
* __variable_path__  
The location to the .tfvar files. You are able to keep all your variables in a separate folder however this is discouraged. ideally this should be the same as the tf_file_path.  
* __variable_files__  
An array of the variable files that need to be pulled into the working directory for execution in this environment.  
* __inline_variables__  
This is a hash or dictionary of variable names and values that will be passed into the terraform executable at run time.
You are able to expand environment variables here using the syntax ${ENV['name_of_variable']}.
No other code can be executed here, and the value of the environment variable will be passed as a string to terraform.  
* __state_file__
Type describes to terraform where it will need to go to get the state file.
config is a hash or dictionary of the values required by terraform to get the file.
See https://www.terraform.io/docs/state/remote/for more details on how remote files work.  
* __custom_args__  
An array of custom runtime values that you would like to pass into your terraform runs.  

The script allows you to get an example json file to work from when you first start. Use the __--json-example__ argument when running the script.

# How do I use it?
__To use the terraform runner you need to have ruby installed. It is required to have a version of ruby 2.0+.__  
No additional gems are required.  
*In a future release of the terraform runner it will be packaged with a version of ruby to run it.*  

Once you have your ruby installed you can use the help menu to build your commands.
Terraform runner help menu
```
$> ruby terraform-runner.rb -h
 
Usage: terraform-runner.rb [options]

Specific options:
    -c, --config-file /path/to/file  Path to config JSON file
    -a, --action action_type         Terraform action: plan, apply, destroy, get
        --update-modules             Forces updates of modules. Only to be used with the get action.
    -f, --force                      No prompts
        --json-example               Prints default JSON file.
    -h, --help                       Displays this screen
    -v, --version                    Display the version
        --debug
```

Below are some examples using the runner to do its job.  
```
ruby terraform-runner.rb -a plan -c config_files\vpc_default.json
ruby terraform-runner.rb -a apply -c config_files\vpc_default.json
ruby terraform-runner.rb -a delete -c config_files\vpc_default.json
ruby terraform-runner.rb -a delete -f -c config_files\vpc_default.json
```
  