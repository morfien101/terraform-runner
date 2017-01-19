#!/usr/bin/ruby
# This program is used to print out the last state file
# generated by the terraform runner. This will help
# make the statefile available outside of the container.

VERSION = '0.0.1'.freeze

TERRAFORM_DIR = '/terraform-runner/'.freeze

class TFStateFile
  def initialize(tf_dir)
    @tf_dir = tf_dir
  end

  # This function looks for the last working directory created
  # by the terraform-runner.rb program.
  def get_last_dir(root)
    Dir.glob("#{root}terraform-runner-working-dir*").sort[-1]
  end

  # This function returns the contents of the state file that
  # was collected by get_last_dir(). If there is no working
  # dir or if the statefile does not exist it will return an
  # empty json file. If it is there it will simply return it
  # so it can be printed out.
  def write_out_statefile
    output ='{}'
    unless get_last_dir(@tf_dir).nil?
      file_location=File.join(get_last_dir(@tf_dir),".terraform","terraform.tfstate")
      output = File.read(file_location) if File.exist?(file_location)
    end
    return output
  end
end
sf = TFStateFile.new(TERRAFORM_DIR)
puts sf.write_out_statefile