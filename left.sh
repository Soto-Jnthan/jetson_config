#!/bin/bash

set -e

password=$1

cd ~

# create new environment with pytorch
python3 -m virtualenv -p python3 ~/.virtualenvs/furuta --system-site-packages
source ~/.virtualenvs/furuta/bin/activate
wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install -U stable-baselines3==1.3.0
pip install -U jaraco.classes==3.2.1
pip install -U jaraco.collections==3.4.0
pip install -U jaraco.functools==3.4.0
pip install -U jaraco.logging==3.1.0
pip install -U jaraco.stream==3.0.3
pip install -U jaraco.text==3.6.0
pip install -U jetson-stats==3.1.1
pip install -U Jetson.GPIO
pip install -U pyglet==1.5.21
pip install -U tensorboard==2.7.0
pip install -U tensorboard-data-server==0.6.1
pip install -U tensorboard-plugin-wit==1.8.0
pip install -U torch-tb-profiler==0.2.1
pip install -U wandb==0.12.6
rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
python3 -m ipykernel install --user --name=furuta
deactivate

# make swapfile
echo $password | sudo -S fallocate -l 4G /var/swapfile
echo $password | sudo -S chmod 600 /var/swapfile
echo $password | sudo -S mkswap /var/swapfile
echo $password | sudo -S swapon /var/swapfile
echo $password | sudo -S bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'

# switch to lubuntu
echo $password | sudo -S apt remove --purge ubuntu-desktop -y
echo $password | sudo -S apt remove --purge gdm3 -y
echo $password | sudo -S apt install lxdm -y
echo $password | sudo -S apt install lxde -y
echo $password | sudo -S apt install --reinstall lxdm -y
echo $password | sudo -S sed -i "s|# autologin=dgod|autologin=$USER|g" /etc/lxdm/lxdm.conf

# start jupyter lab at sturtup
jetsonip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(192.([0-9]*\.){2}[0-9]*).*/\2/p'`
echo $password | sudo -S bash -c "echo \"[Desktop Entry]\" >> /etc/xdg/autostart/jupyterlab.desktop"
echo $password | sudo -S bash -c "echo \"Name=jupyterlab\" >> /etc/xdg/autostart/jupyterlab.desktop"
echo $password | sudo -S bash -c "echo \"Exec=jupyter lab --ip=$jetsonip --no-browser --allow-root\" >> /etc/xdg/autostart/jupyterlab.desktop"

# add aliases for quick access
echo $password | sudo -S echo "alias furuta='source ~/.virtualenvs/furuta/bin/activate'" >> /home/$USER/.bashrc

# setup serial communication
python3 -m pip install pyserial
echo $password | sudo -S adduser $USER dialout

# reboot the system
echo $password | sudo -S reboot