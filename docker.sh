#!/bin/bash
#
# Copyright (C) 2023 Dimas Yudha Pratama <official@dimasyudha.com>
#
#
OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

if [ "$EUID" -ne 0 ];
    then
        echo "You need to run this script with sudo privileges"
        sleep 3
        clear
        exit 1
fi

if [ -z $(getent group docker) ];
    then
        newgrp docker
fi

usermod -aG docker $USER

if [[ $OS == *"Red Hat"* ]] \
   || [[ $OS == *"CentOS"* ]] \
   || [[ $OS == *"Rocky Linux"* ]] \
   || [[ $OS == *"AlmaLinux"* ]];
    then
        yum update -y

        yum remove docker -y docker-client \
                   docker-client-latest \
                   docker-common \
                   docker-latest \
                   docker-latest-logrotate \
                   docker-logrotate \
                   docker-engine
        
        yum install -y yum-utils \
                       device-mapper-persistent-data \
                       lvm2
        
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

        yum install -y docker-ce \
                       docker-ce-cli \
                       containerd.io
elif [[ $OS == *"Ubuntu"* ]];
    then
        apt-get update -y

        apt-get remove -y docker \
                        docker-engine \
                        docker.io \
                        containerd \
                        runc

        apt-get install -y apt-transport-https \
                           ca-certificates \
                           curl \
                           gnupg \
                           lsb-release

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

        add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"

        apt-get install -y docker-ce \
                           docker-ce-cli \
                           containerd.io
else
    echo "The OS that you're using is not supported yet"
    sleep 3
    clear
    exit 1
fi

systemctl enable docker
systemctl start docker

mkdir -p /etc/systemd/system/docker.service.d \
    && echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H fd:// -H unix://var/run/docker.sock" \
    | tee /etc/systemd/system/docker.service.d/override.conf

systemctl daemon-reload
systemctl restart docker.service