#!/usr/bin/ruby
# Copyright 2017 Randy Coburn
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'terraform_runner'

options = Options.get_options(ARGV)
logger = LoggerHelper.get_logger(options)
if InputChecker.new(options,logger).valid?
  runner = TerraformRunner.new(logger, options)
  runner.execute_commands()
  exit runner.tf_exit_code
end
