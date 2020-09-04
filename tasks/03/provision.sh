#!/usr/bin/env bash

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

case $HOSTNAME in
    zbx5-db)
        sudo apt-get install -y mariadb-server
        ;;

    zbx5-srv)
        sudo apt-get install -y zabbix-server-mysql
        ;;

    zbx5-web)
        sudo apt-get install -y zabbix-frontend-php zabbix-nginx-conf
        ;;
    *)
        ;;
esac

reboot
