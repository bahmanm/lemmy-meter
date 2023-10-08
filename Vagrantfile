# -*- mode: ruby; -*-

Vagrant.configure("2") do |config|

  config.vm.provider :libvirt

  config.vm.define :lemmy_meter do |lemmy_meter|
    lemmy_meter.vm.box = "opensuse/Tumbleweed.x86_64"
    lemmy_meter.vm.network "private_network", ip: "192.168.33.10"
    lemmy_meter.vm.synced_folder '.', '/vagrant', disabled: true
  end

  config.vm.provision :ansible do |ansible|
    ansible.verbose = "vv"
    ansible.playbook = "ansible/playbooks/setup_server/setup_server.yml"
    ansible.compatibility_mode = "2.0"
    ansible.raw_arguments = Shellwords.shellsplit(ENV['ANSIBLE_ARGS']) if ENV['ANSIBLE_ARGS']
  end

end
