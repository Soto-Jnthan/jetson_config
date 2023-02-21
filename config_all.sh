#!/bin/bash

set -e

password=$1

cd ~

# upgrade and remove unnecessary libraries
echo $password | sudo -S apt update
echo $password | sudo -S apt upgrade -y
echo $password | sudo -S apt remove --purge libreoffice* -y
echo $password | sudo -S apt autoremove -y
echo $password | sudo -S apt install htop -y

# install necessary dependencies
echo $password | sudo -S apt-get install -y autoconf bc build-essential g++-8 gcc-8 clang-8 lld-8 gettext-base gfortran gfortran-8 llvm-8
echo $password | sudo -S apt-get install -y libfreetype6-dev libhdf5-dev hdf5-tools zip libjpeg8-dev liblapack-dev libblas-dev libhdf5-serial-dev
echo $password | sudo -S apt-get install -y iputils-ping libbz2-dev libc++-dev libcgal-dev libffi-dev libjpeg-dev liblzma-dev libncurses5-dev
echo $password | sudo -S apt-get install -y libncursesw5-dev libpng-dev libreadline-dev libssl-dev libsqlite3-dev libxml2-dev libxslt-dev
echo $password | sudo -S apt-get install -y locales moreutils openssl rsync scons libopenblas-dev libomp-dev libopenmpi-dev cmake zlib1g-dev
echo $password | sudo -S apt-get install -y python3-dev python-openssl python3-pip virtualenv 

# install traitlets (master)
python3 -m pip install traitlets

# install jupyter lab
echo $password | sudo -S apt install -y nodejs npm
python3 -m pip install -U jupyter jupyterlab
python3 -m notebook --generate-config

# set jupyter password
python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"

# set paths
echo $password | sudo -S ln -s /usr/include/locale.h /usr/include/xlocale.h
export "LD_LIBRARY_PATH=/usr/lib/llvm-8/lib:$LD_LIBRARY_PATH"
if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then
  echo "** Add CUDA stuffs into ~/.bashrc"
  echo >> ${HOME}/.bashrc
  echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
fi

# create new environment with stable-baselines2
python3 -m virtualenv -p python3 ~/.virtualenvs/sb2 --system-site-packages
source ~/.virtualenvs/sb2/bin/activate
pip install -U pip testresources setuptools==65.5.0
pip install -U numpy==1.21.1 future==0.18.2 mock==3.0.5 keras_preprocessing==1.1.2 keras_applications==1.0.8 gast==0.4.0
pip install -U protobuf pybind11 cython pkgconfig packaging h5py==3.6.0
pip install -U --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v461 tensorflow==1.15.5+nv22.1
pip install stable-baselines
python3 -m ipykernel install --user --name=sb2
deactivate

# create new environment with stable-baselines3
python3 -m virtualenv -p python3 ~/.virtualenvs/sb3 --system-site-packages
source ~/.virtualenvs/sb3/bin/activate
wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install --upgrade pip
pip install aiohttp numpy=='1.19.4' scipy=='1.5.3'
pip install --upgrade protobuf
pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install -U stable-baselines3==1.3.0
rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
python3 -m ipykernel install --user --name=sb3
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
echo $password | sudo -S echo "alias sb2='source ~/.virtualenvs/sb2/bin/activate'" >> /home/$USER/.bashrc
echo $password | sudo -S echo "alias sb3='source ~/.virtualenvs/sb3/bin/activate'" >> /home/$USER/.bashrc

# setup serial communication
python3 -m pip install pyserial
echo $password | sudo -S adduser $USER dialout

# reboot the system
echo $password | sudo -S apt update
echo $password | sudo -S apt clean -y
echo $password | sudo -S apt autoremove -y
echo $password | sudo -S reboot