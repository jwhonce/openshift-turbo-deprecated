# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile provides a simple default configuration using VirtualBox.
# For any other configuration, create a configuration in .vagrant-openshift.json
# using the vagrant-openshift plugin (https://github.com/openshift/vagrant-openshift)
# as an alternative to editing this file.
# Specific providers may use further configuration from provider-specific files -
# consult the provider definitions below for specifics.

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

# Require a recent version of vagrant otherwise some have reported errors setting host names on boxes
Vagrant.require_version '>= 1.6.2'

def pre_vagrant_171
  @pre_vagrant_171 ||= begin
    req = Gem::Requirement.new('< 1.7.1')
    if req.satisfied_by?(Gem::Version.new(Vagrant::VERSION))
      true
    else
      false
    end
  end
end

class VFLoadError < Vagrant::Errors::VagrantError
  def error_message;
    @parserr;
  end

  def initialize(message, *args)
    @parserr = message
    super(*args)
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # attempt to read config in this repo's .vagrant-openshift.json if present
  if File.exist?('.vagrant-openshift.json')
    json = File.read('.vagrant-openshift.json')
    begin
      vagrant_openshift_config = JSON.parse(json)
    rescue JSON::ParserError => e
      raise VFLoadError.new "Error parsing .vagrant-openshift.json:\n#{e}"
    end
  else
    # this is only used as default when .vagrant-openshift.json does not exist
    vagrant_openshift_config = {
        'instance_name'     => 'origin-turbo',
        'os'                => 'fedora',
        'dev_cluster'       => false,
        'insert_key'        => true,
        'num_minions'       => 1,
        'rebuild_yum_cache' => false,
        'cpus'              => 2,
        'memory'            => 1024,
        'virtualbox'        => {
            'box_name' => 'fedora20_openshift',
            'box_url'  => 'https://mirror.openshift.com/pub/vagrant/boxes/openshift3/fedora_20_latest.box'
        },
        'vmware'            => {
            'box_name' => 'fedora_inst',
            'box_url'  => 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/vmware/opscode_fedora-20_chef-provisionerless.box'
        },
        'libvirt'           => {
            'box_name' => 'fedora_inst',
            'box_url'  => 'https://mirror.openshift.com/pub/vagrant/boxes/openshift3/fedora_libvirt_inst.box'
        },
    }
  end

  sync_from = vagrant_openshift_config['sync_from'] || ENV['VAGRANT_SYNC_FROM'] || '.'
  sync_to   = vagrant_openshift_config['sync_to'] || ENV['VAGRANT_SYNC_TO'] || '/data/src/github.com/openshift/origin'

  ##########################
  # define settings for the single VM being created.
  config.vm.define 'turbo', primary: true do |config|
    config.vm.hostname = 'turbo.local'

    if vagrant_openshift_config['rebuild_yum_cache']
      config.vm.provision 'shell', inline: 'yum clean all && yum makecache'
    end
    if pre_vagrant_171
      config.vm.provision 'shell', path: 'hack/vm-provision.sh', id: 'setup'
    else
      config.vm.provision 'setup', type: 'shell', path: 'hack/vm-provision.sh'
    end

    config.vm.network 'private_network', ip: '172.17.17.17', virtualbox__intnet: true

    config.vm.provision 'shell', inline: '/vagrant/vagrant/provision-turbo.sh'
  end

  # #########################################
  # provider-specific settings defined below:

  # ################################
  # Set VirtualBox provider settings
  config.vm.provider 'virtualbox' do |v, override|
    override.vm.box         = vagrant_openshift_config['virtualbox']['box_name']
    override.vm.box_url     = vagrant_openshift_config['virtualbox']['box_url']
    override.ssh.insert_key = vagrant_openshift_config['insert_key']

    v.memory = vagrant_openshift_config['memory']
    v.cpus   = vagrant_openshift_config['cpus']
    v.customize ['modifyvm', :id, '--cpus', '2']
    # to make the ha-proxy reachable from the host, you need to add a port forwarding rule from 1080 to 80, which
    # requires root privilege. Use iptables on linux based or ipfw on BSD based OS:
    # sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 1080
    # sudo ipfw add 100 fwd 127.0.0.1,1080 tcp from any to any 80 in
  end if vagrant_openshift_config['virtualbox']

end
