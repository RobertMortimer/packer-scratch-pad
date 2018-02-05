#!/bin/bash
#nodestrap5
puppet='https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm'
epel='http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
foreman_ip="192.168.44.5"
foreman_host="p5-foreman.puppet-dev.hpe.com"
puppet_rootdir="/etc/puppetlabs"
puppet_bin="/opt/puppetlabs/bin"

#DXC proxy settings
# export http_proxy=http://16.85.88.10:8080
# export https_proxy=http://16.85.88.10:8080
# export ftp_proxy=http://16.85.88.10:8080
# export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com
#
# grep -- 'proxy=http://16.85.88.10:8080'  /etc/yum.conf ||  echo "proxy=http://16.85.88.10:8080" | sudo tee --append /etc/yum.conf
# grep -- 'export http_proxy=http://16.85.88.10:8080' /etc/bashrc || echo "export http_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
# grep -- 'export https_proxy=http://16.85.88.10:8080' /etc/bashrc || echo "export https_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
# grep -- 'export ftp_proxy=http://16.85.88.10:8080' /etc/bashrc || echo "export ftp_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
# grep -- "export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com" /etc/bashrc || echo "export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com" | sudo tee --append /etc/bashrc

# Update system first
sudo yum update -y #-t --setopt=retries=20
sudo -E yum -y install ${puppet}
sudo -E yum -y install ${epel}

sudo -E yum -y install puppet-agent

#update for dev_emea
# Configure /etc/hosts file
grep -- "${foreman_ip} ${foreman_host}" /etc/hosts || echo "${foreman_ip} ${foreman_host}" | sudo -E tee --append /etc/hosts 2> /dev/null
grep -- "server = ${foreman_host}" ${puppet_rootdir}/puppet/puppet.conf
if [[ $? -ne 0 ]]
then
  echo "" | sudo tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
  echo "    server = ${foreman_host}" | sudo -E tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
  echo "    certname = `hostname -f`" | sudo -E tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
  echo "    runinterval = 120" | sudo -E tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
  echo "    stringify_facts = false" | sudo -E tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
  echo "    log_level = warning" | sudo -E tee --append ${puppet_rootdir}/puppet/puppet.conf 2> /dev/null
fi
#adjust permissions and selinux
grep -- puppet /etc/passwd || sudo useradd puppet

sudo mkdir -p /etc/puppetlabs/code/hieradata/environments/local_dev  && sudo chown -R puppet.puppet /etc/puppetlabs/code/hieradata/environments/local_dev
sudo mkdir -p /etc/puppetlabs/code/modules && sudo chown -R puppet.puppet /etc/puppetlabs/code/modules
sudo mkdir -p /etc/puppetlabs/code/hieradata && sudo chown -R puppet.puppet /etc/puppetlabs/code/hieradata
sudo mkdir -p /etc/puppetlabs/code/environments && sudo chown -R puppet.puppet /etc/puppetlabs/code/environments
sudo semanage fcontext  -a -t puppet_etc_t "${puppet_rootdir}/code/modules(/.*)?"
sudo semanage fcontext  -a -t puppet_etc_t "${puppet_rootdir}/code/environments(/.*)?"
sudo semanage fcontext  -a -t puppet_etc_t "${puppet_rootdir}/code/hieradata(/.*)?"
sudo restorecon -R ${puppet_rootdir}

sudo service puppet stop
sudo service puppet start

sudo ${puppet_bin}/puppet resource service puppet ensure=running enable=true
sudo ${puppet_bin}/puppet agent --enable
