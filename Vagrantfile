# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?('vagrant-env')  # `vagrant plugin install vagrant-env`
    config.env.enable
  end

  config.vm.box = 'base'
  config.nfs.functional = false
  config.smb.functional = false

  config.vm.provision 'ansible_local' do |ansible|
    ansible.config_file = 'ansible.cfg'
    ansible.playbook = 'playbook.yml'

    if ENV['ECOLEX_PROVISION_QUICK']
      ansible.start_at_task = 'ecolex'
    end
  end

  config.vm.provider :vmck do |vmck|
    vmck.vmck_url = ENV['VMCK_URL'] || 'http://10.66.60.1:9995'
    vmck.memory = 12000
    vmck.cpus = 2
  end
end
