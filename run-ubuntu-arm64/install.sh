#!/bin/bash
source /scripts/install.conf
set -e
install_packages()
{
    echo "apt-get update"
    apt-get update
    echo "apt-get -y install $APT_INSTALL"
    apt-get -y install $APT_INSTALL
}
#//install docker reference to https://docs.docker.com/install/linux/docker-ce/ubuntu/
install_docker()
{
    apt-get --no-install-recommends -y install lsb-release apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    #chroot_mount
    curl -fsSL ${DOCKER_UBUNTU_REPO}/gpg | apt-key add -
    echo "add-apt-repository 'deb ${DOCKER_UBUNTU_REPO} $(lsb_release -cs) stable'"
    add-apt-repository "deb ${DOCKER_UBUNTU_REPO} $(lsb_release -cs) stable"
    apt-get update
    apt-get --no-install-recommends -y install docker-ce docker-ce-cli containerd.io
    #download docker-compose.
    wget -o docker-compose $DOCKER_COMPOSE_URL 
    mv -f docker-compose /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
}
config_system()
{
    #setup ttyS0 as our console with 115200
    echo "setup console as ttyS0,115200" 
    systemctl enable serial-getty@ttyS0.service
    sed -i 's/--keep-baud 115200,38400,9600/115200/g' /lib/systemd/system/serial-getty@.service
    echo "change root passwd to ${rootpasswd}"
    #run_cmd /bin/bash -c "echo -e '${rootpasswd}\n${rootpasswd}\n' | passwd"
    /bin/bash -c "echo 'root:${rootpasswd}' | chpasswd"

    echo "add $newuser account"
    useradd -G sudo -m -s /bin/bash ${newuser}
    usermod -aG docker ${newuser}
    #force update password in first login.
    #passwd -e ${newuser}
    echo ${newuser}:${newuser_passwrd} | chpasswd
    #hostname
    echo ${MY_HOSTNAME} > ${install_dir}/etc/hostname
    echo 127.0.0.1	localhost > ${install_dir}/etc/hosts
    echo 127.0.0.1	${MY_HOSTNAME} >> ${install_dir}/etc/hosts

	# This DNS used in runtime
	sed -i 's/#DNS=/DNS=8.8.8.8/g' /etc/systemd/resolved.conf
	sed -i 's/#LLMNR=no/LLMNR=no/g' /etc/systemd/resolved.conf

    echo "\n==========  ==========================\n"
    echo "$install_dir is the final output"
    echo "root password is ${rootpasswd}"
    echo "new user is ${newuser}:${newuser_passwrd}"
    echo "\n====================================\n"
    apt-get clean
}
install_packages
install_docker
config_system