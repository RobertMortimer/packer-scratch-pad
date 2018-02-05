#!/bin/bash

# Run on VM to bootstrap Puppet Agent nodes
  sudo ifup eth1
if ps aux | grep "puppet agent" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
  # export http_proxy=http://16.85.88.10:8080
  # export https_proxy=http://16.85.88.10:8080
  # export ftp_proxy=http://16.85.88.10:8080
  # export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com
  # echo "proxy=http://16.85.88.10:8080" | sudo tee --append /etc/yum.conf

    # Update system first
    sudo yum update -y #-t --setopt=retries=20


    # Install rsync for shared folders
    sudo yum -y install rsync

    # Install Puppet for CentOS7
    sudo yum install -y http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    sudo yum -y install puppet

    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.44.5    foreman.puppet-dev.hpe.com foreman puppet" | sudo tee --append /etc/hosts 2> /dev/null

    # Add agent section to /etc/puppet/puppet.conf (sets run interval to 120 seconds)
    echo "" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null
    echo "    server = foreman.puppet-dev.hpe.com" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null
    echo "    runinterval = 120" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null

    sudo service puppet stop
    sudo service puppet start

    sudo puppet resource service puppet ensure=running enable=true
    sudo puppet agent --enable

    #preserve proxy settings
    echo "proxy=http://16.85.88.10:8080" | sudo tee --append /etc/yum.conf
    echo "export http_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    echo "export https_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    echo "export ftp_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    echo "export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com" | sudo tee --append /etc/bashrc
fi
