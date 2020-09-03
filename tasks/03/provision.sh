#!/usr/bin/env bash

#SRV2='web'
#SRV1='elk'
#ANSIBLE_SERVER='log'
#SRV2_IP='192.168.50.30'
#SRV1_IP='192.168.50.20'
#KEY='/home/vagrant/.ssh/id_rsa'
#KEY_PUB=$KEY'.pub'


# Подключение репозитория Zabbix и обновление системы
wget https://repo.zabbix.com/zabbix/5.0/debian/pool/main/z/zabbix-release/zabbix-release_5.0-1+buster_all.deb
sudo dpkg -i zabbix-release_5.0-1+buster_all.deb
sudo apt-get update -y && sudo apt-get upgrade -y

# Установка часового пояса
sudo timedatectl set-timezone Europe/Moscow

# Установка русской локали
sudo echo "locales locales/default_environment_locale select ru_RU.UTF-8" | sudo debconf-set-selections
sudo echo "locales locales/locales_to_be_generated multiselect ru_RU.UTF-8 UTF-8" | sudo debconf-set-selections
sudo rm "/etc/locale.gen"
sudo dpkg-reconfigure --frontend noninteractive locales

# Установка дополнительных пакетов
sudo apt-get install -y htop mc tree zabbix-agent
sudo systemctl zabbix-agentd stop

case $HOSTNAME in
    $ANSIBLE_SERVER)
        yum install -y epel-release
        yum install -y ansible ansible-lint nano sshpass tmux
        # Возможность использования имен серверов вместо IP-адресов
        echo "$SRV2_IP  $SRV2" >> /etc/hosts
        echo "$SRV1_IP  $SRV1" >> /etc/hosts
        # Запретить SSH-клиенту при подключении к хосту осуществлять
        # проверку подлинности его ключа.
        sed -i '35s/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' \
            /etc/ssh/ssh_config

        # Чтобы не вводить пароль при добавлении публичного ключа
        runuser -l vagrant -c "ssh-keygen -t rsa -N '' -b 2048 -f $KEY"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV2"
        runuser -l vagrant -c "sshpass -p vagrant ssh-copy-id -i $KEY_PUB $SRV1"

        cp -r /vagrant/ansible-log/ /home/vagrant/
        chown -R vagrant:vagrant /home/vagrant/ansible-log
        ;;

    'zbx5-db')
        apt-get install mariadb-server zabbix-server-mysql
        ;;

    'zbx5-srv')
        apt-get install zabbix-server-mysql
        ;;

    'zbx5-web')
        apt-get install zabbix-frontend-php zabbix-nginx-conf
        ;;

esac

reboot
