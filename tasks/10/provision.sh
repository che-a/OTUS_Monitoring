#!/usr/bin/env bash

SRV='prom'
CLIENT1='web1'

SRV_IP='192.168.50.10'
CLIENT1_IP='192.168.50.20'


sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y tree wget

# Установка часового пояса
timedatectl set-timezone Europe/Moscow

# Установка русской локали
sudo echo "locales locales/default_environment_locale select ru_RU.UTF-8" | sudo debconf-set-selections
sudo echo "locales locales/locales_to_be_generated multiselect ru_RU.UTF-8 UTF-8" | sudo debconf-set-selections
sudo rm "/etc/locale.gen"
sudo dpkg-reconfigure --frontend noninteractive locales

# Установка node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz &> /dev/null
tar zxvf node_exporter-*.linux-amd64.tar.gz
cd node_exporter-*.linux-amd64

sudo cp node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false nodeusr
sudo chown -R nodeusr:nodeusr /usr/local/bin/node_exporter

sudo cp /home/vagrant/node_exporter.service /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter.service


case $HOSTNAME in
    $SRV)
        # Установка Apache Benchmark
        sudo apt install -y apache2-utils
        # Возможность использования имен серверов вместо IP-адресов
        echo "$CLIENT1_IP  $CLIENT1" >> /etc/hosts

        # Установка Prometheus server
        wget https://github.com/prometheus/prometheus/releases/download/v2.21.0/prometheus-2.21.0.linux-amd64.tar.gz &> /dev/null
        tar zxvf prometheus-*.linux-amd64.tar.gz && cd prometheus-*.linux-amd64

        sudo mkdir /etc/prometheus /var/lib/prometheus

        sudo cp prometheus promtool /usr/local/bin/
        sudo cp -r console_libraries consoles prometheus.yml /etc/prometheus

        sudo cp /home/vagrant/prometheus.yml /etc/prometheus/prometheus.yml

        sudo useradd --no-create-home --shell /bin/false prometheus
        sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
        sudo chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}

        # Настройка автозапуска через systemd
        sudo cp /home/vagrant/prometheus.service /etc/systemd/system/prometheus.service
        sudo systemctl daemon-reload
        sudo systemctl enable prometheus
        sudo chown -R prometheus:prometheus /var/lib/prometheus
        sudo systemctl start prometheus

        # Установка alertmanager
        cd
        wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz &> /dev/null
        tar zxvf alertmanager-*.linux-amd64.tar.gz && cd alertmanager-*.linux-amd64

        sudo mkdir /etc/alertmanager /var/lib/prometheus/alertmanager

        sudo cp alertmanager amtool /usr/local/bin/
        sudo cp alertmanager.yml /etc/alertmanager

        sudo useradd --no-create-home --shell /bin/false alertmanager
        chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/prometheus/alertmanager
        chown alertmanager:alertmanager /usr/local/bin/{alertmanager,amtool}

        # Настройка автозапуска через systemd
        sudo cp /home/vagrant/alertmanager.service /etc/systemd/system/alertmanager.service
        sudo systemctl daemon-reload
        sudo systemctl enable alertmanager
        sudo systemctl start alertmanager

        ;;

    $CLIENT1)
        sudo apt install -y \
            php php-bcmath php-bz2 php-intl php-gd php-mbstring \
            php-mysql php-mysql php-zip php-fpm php-dom php-fileinfo \
            php-iconv php-json php-pdo php-phar php-simplexml php-xml \
            php-curl
        sudo systemctl enable php7.3-fpm.service
        sudo apt install -y nginx
        sudo systemctl enable nginx

        # Установка nginx_exporter
        cd
        wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.8.0/nginx-prometheus-exporter-0.8.0-linux-amd64.tar.gz &> /dev/null
        tar zxvf nginx-prometheus-exporter-*linux-amd64.tar.gz

        sudo useradd --no-create-home --shell /bin/false prometheus
        #sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
        sudo chown prometheus:prometheus /usr/local/bin/nginx-prometheus-exporter

        sudo cp nginx-prometheus-exporter  /usr/local/bin/
        # Настройка автозапуска через systemd
        sudo cp /home/vagrant/nginx_exporter.service /etc/systemd/system/nginx_exporter.service
        sudo systemctl daemon-reload
        sudo systemctl enable nginx_exporter.service
        #sudo systemctl start nginx_exporter.service
        ;;
esac

reboot
