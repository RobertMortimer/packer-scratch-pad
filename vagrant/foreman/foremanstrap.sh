#!/bin/bash

# Run on VM to bootstrap Foreman server
FWPORTS="22 80 443 8140"
puppet='https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm'
epel='http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'
foreman='https://yum.theforeman.org/releases/1.16/el7/x86_64/foreman-release.rpm'

#exit
echo "START `basename $0`"
if ps aux | grep "/usr/share/foreman" | grep -v grep 2> /dev/null
then
    echo "Foreman appears to all already be installed. Exiting..."
else
    #sudo ifup eth1
    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    ALTNAMES=puppet,hpess-puppet-emea.ssn.hpe.com,hpess-puppet-uk.ssn.hpe.com
    fqdn="p5-foreman.puppet-dev.hpe.com"
    host=$(sed "s/$fqdn/\.*/g")
    hostip="192.168.44.5"
    cat /etc/hosts |grep -v 127.0.0.1 |grep -- "$fqdn" >/dev/null
    if [[ $? -eq 0 ]]
    then
      echo "/etc/hosts already has ${hostip}  ${fqdn} ${host}"
    else
      echo "$hostip  $fqdn foreman ${host}" | sudo -E tee --append /etc/hosts 2> /dev/null
    fi
    #set proxys
    # export http_proxy=http://16.85.88.10:8080
    # export https_proxy=http://16.85.88.10:8080
    # export ftp_proxy=http://16.85.88.10:8080
    # export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com
    # cat /etc/yum.conf |grep -- 'proxy=http://16.85.88.10:8080'
    # if [[ $? -ne 0 ]]
    # then
    #   echo "proxy=http://16.85.88.10:8080" | sudo tee --append /etc/yum.conf
    # fi
  # Update system first
    sudo -E yum --disablerepo=puppet5 update -y #-t --setopt=retries=20
    #sudo yum install -y git git-flow rsync

    #setip dirs for modules
    sudo mkdir -p /etc/puppetlabs/code/hieradata/{common,environment}
    sudo mkdir -p /etc/puppetlabs/code/modules/{mss,forge}
    #sudo mkdir -p /code/puppet-modules

    # Install Foreman for CentOS7

    sudo -E yum -y install ${puppet}
    sudo -E yum -y install ${epel}
    sudo -E yum -y install ${foreman}

    echo "/usr/sbin/foreman-installer --enable-foreman-plugin-puppetdb --puppet-dns-alt-names ${ALTNAMES} --foreman-db-database ${REGION}_foreman --foreman-db-password ${DBPW} --puppet-show-diff true" > install.cmd
    sudo -E yum -y install foreman-installer
    echo "Repos installed, lets try installing foreman-installer"
    #sudo -E foreman-installer  --enable-foreman-plugin-puppetdb --puppet-dns-alt-names ${ALTNAMES} --foreman-db-database dev_foreman --foreman-db-password Yablonski2012! --foreman-admin-password Yablonski2012! --puppet-show-diff true
    sudo -E foreman-installer  --enable-foreman-plugin-puppetdb --foreman-db-database dev_foreman --foreman-db-password Yablonski2012! --foreman-admin-password Yablonski2012! --puppet-show-diff true

    #echo "Linking sync locations"
    #sudo mkdir -p /code/puppet-modules

    #sudo ln -s /etc/puppetlabs/code/modules/forge /code/puppet-modules/forge
    #sudo ln -s /etc/puppetlabs/code/modules/mss /code/puppet-modules/mss
    #sudo ln -s /etc/puppetlabs/code/hieradata/common/ /code/puppet-default-data
    #sudo ln -s /etc/puppetlabs/code/hieradata/environment/ /code/puppet-region-data

    # dont do the rm if using shares
    #sudo rm -rf /etc/puppetlabs/environments/*
    #sudo mkdir /etc/puppetlabs/code/environments/{production,dev_emea,dev_ams,dev_apj}

    sudo chown -R puppet:puppet /etc/puppetlabs/code/modules
    sudo chown -R puppet:puppet /etc/puppetlabs/code/hieradata
    sudo chown -R puppet:puppet /etc/puppetlabs/code/environments
    sudo chmod o+s /etc/puppetlabs/code/modules/{mss,forge}
    sudo chmod o+s /etc/puppetlabs/code/hieradata/{common,environment}
    sudo chmod o+s /etc/puppetlabs/code/environments

# Set hiera.yaml
sudo cat > /etc/puppetlabs/puppet/hiera.yaml <<xif34
---
:backends:
  - yaml
  - json
:yaml:
  :datadir: /etc/puppetlabs/code/hieradata/
:json:
  :datadir: /etc/puppetlabs/code/hieradata/
:hierarchy:
  - "environment/%{::environment}/node/%{::clientcert}"
  - "environment/%{::environment}/%{::operatingsystem}_%{::operatingsystemmajrelease}"
  - "environment/%{::environment}/local"
  - "common/%{::operatingsystem}_%{::operatingsystemmajrelease}"
  - common/default

xif34

    OLD='/etc/puppetlabs/code/environments/common:/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules'
    NEW='/etc/puppetlabs/code/modules/forge:/etc/puppetlabs/code/modules/mss'
    sudo sed -i "s|${OLD}|${NEW}|g" /etc/puppetlabs/puppet/puppet.conf

    # Update answers file
    # update these lines
    OLD1='- /etc/puppetlabs/code/modules'
    NEW1='- /etc/puppetlabs/code/modules/forge'
    sudo sed -i "s|${OLD1}|${NEW1}|g" /etc/foreman-installer/scenarios.d/foreman-answers.yaml
    OLD2='- /etc/puppetlabs/code/environments/common'
    NEW2='- /etc/puppetlabs/code/modules/mss'
    sudo sed -i "s|${OLD2}|${NEW2}|g" /etc/foreman-installer/scenarios.d/foreman-answers.yaml
    sudo sed -i "s/^    autosign.*/    autosign = true/g" /etc/puppetlabs/puppet/puppet.conf
        #OLD3='- /etc/puppet/modules/mss/forge'
    #NEW3='- /etc/puppet/modules/forge'
    #sed -i "s|${OLD3}|${NEW3}|g" /etc/foreman-installer/scenarios.d/foreman-answers.yaml
    # Remove this line
    #OLD4='- \/usr\/share\/puppet\/modules'
    #sed -i "/${OLD4}/d" /etc/foreman-installer/scenarios.d/foreman-answers.yaml

    sudo mkdir -p /etc/puppet/environments/local_dev
    sudo chown -R puppet.puppet /etc/puppetlabs/code/modules
    sudo chown -R puppet.puppet /etc/puppetlabs/code/hieradata
    sudo chown -R puppet.puppet /etc/puppetlabs/code/environments
    sudo semanage fcontext  -a -t puppet_etc_t "/etc/puppetlabs/code/modules(/.*)?"
    sudo semanage fcontext  -a -t puppet_etc_t "/etc/puppetlabs/code/environments(/.*)?"
    sudo semanage fcontext  -a -t puppet_etc_t "/etc/puppetlabs/code/hieradata(/.*)?"
    sudo restorecon -R /etc/puppetlabs/
    #chcon -R --reference=common /code/puppet-modules/

    sudo systemctl restart puppetserver
    sudo systemctl restart foreman
    sudo systemctl restart foreman-proxy
    sudo systemctl restart httpd
    sudo systemctl restart puppet

    # If we set a proxy squirt it into yum.conf for now
    # sudo   echo "proxy=${http_proxy}" >> /etc/yum.conf

    sudo systemctl restart foreman
    sudo systemctl restart httpd

    # First run the Puppet agent on the Foreman host which will send the first Puppet report to Foreman,
    # automatically creating the host in Foreman's database
    sudo -E puppet agent --test --waitforcert=60

    #preserve proxy settings
    # echo "proxy=http://16.85.88.10:8080" | sudo tee --append /etc/yum.conf
    # echo "export http_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    # echo "export https_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    # echo "export ftp_proxy=http://16.85.88.10:8080" | sudo tee --append /etc/bashrc
    # echo "export no_proxy=localhost,`hostname -f`,*.puppet-dev.hpe.com" | sudo tee --append /etc/bashrc

    #adjusting firewalld
    for port in ${FWPORTS}
    do
      iptables-save | grep $port
      if [[ $? -ne 0 ]]
      then
        firewall-cmd --zone=public --add-port=$port/tcp --permanent
        firewall-cmd --reload
      fi
    done
    #tidy environments move common to dev_emea
fi
echo "FIN! `basename $0`"
