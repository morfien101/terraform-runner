# Bring in our source files
require_relative 'src/modules_lib'
require_relative 'src/logger_lib'
require_relative 'src/options_lib'
require_relative 'src/input_checker'
require_relative 'src/command_builder_lib'
require_relative 'src/command_lib'
require_relative 'src/config_file_lib'
require_relative 'src/terraform_lib'

# The version of the program is in here.
require_relative 'src/version'

require 'fileutils'
require 'time'
require 'english'
