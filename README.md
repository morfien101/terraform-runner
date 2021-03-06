# What is the Terraform runner

The terraform-runner.rb script was written to over come some of the limitation of terraform.
It is used to deploy code to different environments. It is written in ruby and is designed to be able to work on windows, mac and linux.

The config files are written in json and describe the variables and files that need to be run. It will also download the current version of the terraform state file that is stored in S3 currently. This could technically be any supported backend remote state file but, has only been tested with S3.

#### The process when running the script is as follows.
1. Create the directory "terraform-runner-working-dir-<datetime>".  
2. Copy the contents of the project specified in the json file to the working directory.  
3. Download a copy of the current remote terraform state file. It will be stored in "terraform-runner-working-dir/.terraform".  
4. Run the terraform command with the supplied action.  
5. Output the STDOUT from the terraform executable.  

This process was designed to work with tools like Jenkins.

Due to limitation in the __windows__ supplied version on ruby standard gems. The STDOUT of the terraform command will be shown only once the command has completed execution.
This is because of buffering of STDOUT in C libraries which is vastly outside the scope of this README.
However it will make the terraform runner look like it has frozen until the run is complete.

# What does the config file look like

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
__To use the terraform runner directly you need to have ruby installed. It is required to have a version of ruby 2.0+.__
*__You have to have the terraform binaries expanded on your computer and available in one of your PATH directories already__*.

__The terraform runner repo now contains a Linux based container that has all the required gems and run time components required to run.__

It also contains a Vagrant file that will download and boot up a Linux machine to run the container. The vagrant file should be in the root of your terraform directory as the launch container script (also provided) will link your working directory into the container.

If you are running on Windows you need to have a SSH Client installed to get into the vagrant machine with. Consider using gitbash ( https://git-scm.com/download/win )

## What does all this mean for you?
1. Clone the repo.
1. Create your configuration files in the scripts directory. See this repo for some example scripts. ( https://github.com/morfien101/terraform-scripts ) (If you are going to use my examples you need to change the bucket in the config files. This will make sense if you are using that repo.)
1. Fire up your vagrant machine with "vagrant up"
1. SSH into your Vagrant VM.
1. Add environment variables for your providers authentication requirements. Unless you have passed in credential files. See below.
1. Run the terraform runner as covered above or see below for some examples.

## Credentials
### Credential files
Credential files can be passed into the container. You will need to set an environment variable called __TERRAFORM_CREDS_FILES__ with the list of directories that you want to be passed in separated by a "__;__".

These files will then be available for use in your scripts in the directory __/terraform-runner/creds/__

```sh
export TERRAFORM_CREDS_FILES="c:\users\awesome person\.aws;c:\users\awesome person\.chef"
```

## Custom Terraform commands
The Terraform runner will let you pass in terraform commands that are not wrapped. This is more for advanced users that want to push commands to terraform that are not specifically wrapped by the runner.

To do this you make use of the --custom-command flag. This has a optional flag that will also digest your variables in the JSON file --custom-command-vars.

See the example commands below for examples of how to use this.

Please note that this command will still be the second command that gets executed in the flow. The first command being the init command.

```
[root@50b6d961faf3 terraform-runner]# ls -lha /terraform-runner/creds/
total 12K
drwxr-xr-x 4 root root 4.0K Feb 23 17:27 .
drwxr-xr-x 5 root root 4.0K Feb 23 17:33 ..
drwxrwxrwx 1 1000 1000    0 Mar 23  2016 .aws
drwxrwxrwx 1 1000 1000 4.0K Feb  6 14:59 .chef
```
### Credentials as Environmental variables
If you choose not to pass in your credentials as a file you will need to create the environment variables that you need for your providers that you are making use of.

These can be looked up in the terraform documentation.
As an example the AWS provisioner requires
```sh
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
```

You can see the this in this document file:
https://www.terraform.io/docs/providers/aws/index.html

## The help menu

Once you have your ruby installed or you are using the container you can use the help menu to build your commands.
Terraform runner help menu
```
$> ./terraform-runner -h

-c, --config-file /path/to/file  Path to config JSON file
    -a, --action action_type         Terraform action: plan, apply, destroy, get, output
    -p, --custom-parameters ARGS     Parameters that will be added as is to the Terraform run.
                                     Presented as a comma sperated string "-arg1,-arg2"
        --custom-command             Allows you to run custom commands on the Terraform run phase.
                                     Encase spaces in quotes.
                                     Example: "taint -allow-missing"
        --custom-command-vars        Add the variables from the json file to the end of the custom command.
        --update-modules             Forces updates of modules. Only to be used with the get action.
    -f, --force                      No prompts
        --json-example               Prints default JSON file.
    -h, --help                       Displays this screen
    -v, --version                    Display the version
        --debug
```

Below are some examples using the runner to do its job.  
```
./terraform-runner -c config_files\vpc_default.json
./terraform-runner -a apply -c config_files\vpc_default.json
./terraform-runner -a destroy -c config_files\vpc_default.json
./terraform-runner -a destroy -f -c config_files\vpc_default.json
./terraform-runner --custom--command "taint -allow-missing resource.name.id"
```

# Getting involved.
Comments, feature requests and improvements are welcome.
Use the normal git methods...
