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

    if ENV['ECOLEX_PROVISION_START_AT']
      ansible.start_at_task = ENV['ECOLEX_PROVISION_START_AT']
    end

    vars = {}
    vars['wireguard_conf'] = ENV['WIREGUARD_CONF'] if ENV['WIREGUARD_CONF']
    ansible.host_vars = {'default' => vars}

    if ENV['DEBUG']
      ansible.verbose = 'vvv'
    end
  end

  config.vm.provider :vmck do |vmck|
    vmck.vmck_url = ENV['VMCK_URL'] || 'http://10.66.60.1:9995'
    vmck.memory = 12000
    vmck.cpus = 2
    if ENV['VMCK_USBSTICK']
      vmck.usbstick = ENV['VMCK_USBSTICK']
    end
  end
end
