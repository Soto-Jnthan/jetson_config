#!/bin/sh

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
echo $password | sudo -S apt-get install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev autoconf bc g++-8 gcc-8 clang-8  
echo $password | sudo -S apt-get install -y libatlas-base-dev libfreetype6-dev build-essential lld-8 gettext-base gfortran-8 iputils-ping
echo $password | sudo -S apt-get install -y libbz2-dev libc++-dev libcgal-dev libffi-dev libjpeg-dev liblzma-dev libncurses5-dev libxslt-dev
echo $password | sudo -S apt-get install -y libncursesw5-dev libpng-dev libreadline-dev libssl-dev libsqlite3-dev libxml2-dev locales moreutils
echo $password | sudo -S apt-get install -y openssl python-openssl rsync scons libopenblas-dev
echo $password | sudo -S apt install -y python3-pip python3-dev python3-smbus cmake
python3 -m pip install -U pip testresources setuptools
python3 -m pip install flask
python3 -m pip install -U numpy==1.18.3
python3 -m pip install pillow==7.1.2
python3 -m pip install matplotlib==3.2.1
python3 -m pip install pandas==1.0.3
python3 -m pip install scipy==1.4.1
python3 -m pip install cython
python3 -m pip install scikit-learn==0.22.0
python3 -m pip install seaborn==0.10.1
python3 -m pip install -U future mock h5py keras_preprocessing keras_applications gast enum34 futures protobuf grpcio 
python3 -m pip install -U absl-py py-cpuinfo psutil portpicker six mock requests astor termcolor protobuf wrapt google-pasta
echo $password | sudo -S apt-get install -y virtualenv

# install traitlets (master)
python3 -m pip install traitlets

# install jupyter lab
echo $password | sudo -S apt install -y nodejs npm
python3 -m pip install -U jupyter jupyterlab
jupyter lab --generate-config

# set jupyter password
python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"

# set paths
export "LD_LIBRARY_PATH=/usr/lib/llvm-8/lib:$LD_LIBRARY_PATH"
if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then
  echo "** Add CUDA stuffs into ~/.bashrc"
  echo >> ${HOME}/.bashrc
  echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
fi

# create new environment with pytorch
mkdir ~/Furuta
python3 -m virtualenv -p python3 ~/Furuta/venv --system-site-packages
source ~/Furuta/venv/bin/activate
wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
pip install -U stable-baselines3==1.3.0
pip install -U backports.entry-points-selectable==1.1.1
pip install -U cachetools==4.2.4
pip install -U certifi==2021.10.8
pip install -U cfgv==3.3.1
pip install -U charset-normalizer==2.0.7
pip install -U click==8.0.3
pip install -U cloudpickle==2.0.0
pip install -U configparser==5.0.2
pip install -U cycler==0.11.0
pip install -U Cython==0.29.24
pip install -U dataclasses==0.8
pip install -U distlib==0.3.3
pip install -U distro==1.6.0
pip install -U docker-pycreds==0.4.0
pip install -U filelock==3.4.0
pip install -U flake8==4.0.1
pip install -U gitdb==4.0.7
pip install -U GitPython==3.1.20
pip install -U google-auth==2.3.0
pip install -U google-auth-oauthlib==0.4.6
pip install -U grpcio==1.41.0
pip install -U gym-cartpole-swingup==0.1.0
pip install -U identify==2.4.0
pip install -U idna==3.3
pip install -U importlib-metadata==4.2.0
pip install -U importlib-resources==5.4.0
pip install -U irc==19.0.1
pip install -U jaraco.classes==3.2.1
pip install -U jaraco.collections==3.4.0
pip install -U jaraco.functools==3.4.0
pip install -U jaraco.logging==3.1.0
pip install -U jaraco.stream==3.0.3
pip install -U jaraco.text==3.6.0
pip install -U jetson-stats==3.1.1
pip install -U Jetson.GPIO==2.0.17
pip install -U kiwisolver==1.3.1
pip install -U Markdown==3.3.4
pip install -U matplotlib==3.3.4
pip install -U mccabe==0.6.1
pip install -U more-itertools==8.12.0
pip install -U nodeenv==1.6.0
pip install -U numpy==1.19.3
pip install -U oauthlib==3.1.1
pip install -U packaging==21.2
pip install -U pandas==1.1.5
pip install -U pathtools==0.1.2
pip install -U Pillow==8.4.0
pip install -U pip-autoremove==0.10.0
pip install -U pkg_resources==0.0.0
pip install -U platformdirs==2.4.0
pip install -U pre-commit==2.15.0
pip install -U promise==2.3
pip install -U protobuf==3.18.1
pip install -U psutil==5.8.0
pip install -U pyasn1==0.4.8
pip install -U pyasn1-modules==0.2.8
pip install -U pycodestyle==2.8.0
pip install -U pyflakes==2.4.0
pip install -U pyglet==1.5.21
pip install -U pyparsing==2.4.7
pip install -U python-dateutil==2.8.2
pip install -U pytz==2021.3
pip install -U PyYAML==6.0
pip install -U requests==2.26.0
pip install -U requests-oauthlib==1.3.0
pip install -U rsa==4.7.2
pip install -U scikit-build==0.12.0
pip install -U scipy==1.5.3
pip install -U sentry-sdk==1.4.3
pip install -U shortuuid==1.0.1
pip install -U six==1.16.0
pip install -U smmap==4.0.0
pip install -U spidev==3.5
pip install -U subprocess32==3.5.4
pip install -U tempora==4.1.2
pip install -U tensorboard==2.7.0
pip install -U tensorboard-data-server==0.6.1
pip install -U tensorboard-plugin-wit==1.8.0
pip install -U termcolor==1.1.0
pip install -U toml==0.10.2
pip install -U torch-tb-profiler==0.2.1
pip install -U typing-extensions==3.10.0.2
pip install -U urllib3==1.26.7
pip install -U wandb==0.12.6
pip install -U Werkzeug==2.0.2
pip install -U yaspin==2.1.0
pip install -U zipp==3.6.0
rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
python3 -m ipykernel install --user --name=Furuta
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
echo $password | sudo -S echo "alias furuta='source ~/Furuta/venv/bin/activate'" >> /home/$USER/.bashrc

# setup serial communication
python3 -m pip install pyserial
echo $password | sudo -S adduser $USER dialout

# reboot the system
echo $password | sudo -S reboot