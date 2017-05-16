# -*- mode: ruby -*-
# vi: set ft=ruby :
$containter_provision = <<EOF
if [ $(grep -c launch_terraform_container.sh /etc/bash.bashrc) == "0" ]; then
  echo "/vagrant/launch_terraform_container.sh" >> /etc/bash.bashrc
  echo "update"
fi
EOF

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu-16.10_withDocker_Go"
  box_name = "ubuntu-16.10-amd64-virtualbox.box"
  box_url = "https://dl.dropboxusercontent.com/u/43087169/#{box_name}"
  box_file = "c:/Users/randy.coburn/Dropbox (Personal)/public/#{box_name}"
  if File.exist?(box_file)
          config.vm.box_url = File.join("file://",box_file)
  else
          config.vm.box_url = box_url
  end

  config.vm.define "runner" do |runner|
    runner.vm.provider "virtualbox" do |vb|
      vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ]
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      vb.cpus = 2
      vb.memory = 2048
      vb.linked_clone = true
    end
    runner.vm.hostname = "runner"
    runner.vm.network "private_network", ip: "172.20.20.90"
    unless ENV['TERRAFORM_CREDS_FILES'].nil?
      ENV['TERRAFORM_CREDS_FILES'].split(";").each do |file|
        config.vm.synced_folder file, "/usercreds/#{File.basename(file)}"
      end
    end
    runner.vm.provision "shell", inline: "docker pull morfien101/terraform-runner"
    runner.vm.provision "shell", inline: $containter_provision
  end
end
