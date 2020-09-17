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

case $HOSTNAME in
    $SRV)
        # Возможность использования имен серверов вместо IP-адресов
        echo "$CLIENT1_IP  $CLIENT1" >> /etc/hosts

        wget https://github.com/prometheus/prometheus/releases/download/v2.21.0/prometheus-2.21.0.linux-amd64.tar.gz &> /dev/null
        tar zxvf prometheus-*.linux-amd64.tar.gz && cd prometheus-*.linux-amd64

        sudo mkdir /etc/prometheus /var/lib/prometheus

        sudo cp prometheus promtool /usr/local/bin/
        sudo cp -r console_libraries consoles prometheus.yml /etc/prometheus

        sudo useradd --no-create-home --shell /bin/false prometheus
        sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
        sudo chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}

        # Настройка автозапуска через systemd
        sudo cp /home/vagrant/prometheus.service /etc/systemd/system/prometheus.service
        # Перечитываем конфигурацию systemd:
        sudo systemctl daemon-reload

        # Разрешаем автозапуск:
        sudo systemctl enable prometheus

        # После ручного запуска мониторинга, который мы делали для проверки, могли сбиться права на папку библиотек — снова зададим ей владельца:
        sudo chown -R prometheus:prometheus /var/lib/prometheus

        # Запускаем службу:
        sudo systemctl start prometheus

        # ... и проверяем, что она запустилась корректно:
        #systemctl status prometheus


        ;;

    $CLIENT1)
        ;;
esac

reboot
