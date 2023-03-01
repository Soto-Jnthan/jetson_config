#!/bin/bash

SCRIPTPATH="$(realpath $0)"

setup_step1()
{	
    sudo apt install -y ntp ntpdate
    sudo dpkg-reconfigure ntp
    ntpq -p
    timedatectl set-ntp true
    sudo systemctl restart systemd-timedated systemd-timesyncd
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* nodejs* -y
    sudo apt install -y nano htop dkms npm python3-pip virtualenv libzmq3-dev libffi-dev libssl1.0-dev 
    sudo apt install -y libhdf5-serial-dev hdf5-tools libpng-dev libfreetype6-dev libblas-dev libopenblas-base libopenmpi-dev
    if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then 
        echo "** Add CUDA stuffs into ~/.bashrc"
        echo >> ${HOME}/.bashrc
        echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
    fi
    echo >> ${HOME}/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${HOME}/.bashrc
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
}

setup_step2()
{
    sudo npm cache clean -f
    sudo npm install -g n
    sudo n 16
    create_SB3_env
    sudo -H python3 -m pip install -U jetson-stats==3.1.4
    sudo systemctl restart jetson_stats.service
    sudo adduser $USER dialout
    install_wifi_drivers	
    install_fan_drivers
}

create_SB3_env()
{
    python3 -m virtualenv -p python3 ~/.virtualenvs/sb3
    echo "alias sb3='source ~/.virtualenvs/sb3/bin/activate'" >> ${HOME}/.bashrc
    source ~/.virtualenvs/sb3/bin/activate
    wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python -m pip install -U pip testresources setuptools 
    python -m pip install -U numpy==1.19.4 
    python -m pip install -U scipy==1.5.3
    python -m pip install -U matplotlib Cython packaging
    python -m pip install jupyterlab Jetson.GPIO pyserial
    python -m pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python -m pip install -U stable-baselines3==1.3 tensorboard
    rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python -m ipykernel install --user --name=sb3
    deactivate
}

install_wifi_drivers()
{
    git clone -b v5.6.4.2 https://github.com/aircrack-ng/rtl8812au.git
    cd rtl*
    sudo make dkms_install
    cd ..
    sudo rm -r rtl8812au
}

install_fan_drivers()
{
    git clone https://github.com/Pyrestone/jetson-fan-ctl
    cd jetson-fan-ctl
    sudo ./install.sh
    cd ..
    sudo rm -r jetson-fan-ctl
}

setup_step3()
{
    setup_jupyterlab
    make_swapfile
    sudo -S apt clean -y && sudo -S apt autoremove -y
}

setup_jupyterlab()
{
    source ~/.virtualenvs/sb3/bin/activate
    jupyter labextension install @jupyter-widgets/jupyterlab-manager
    jupyter lab --generate-config
    jupyter server password
    deactivate	
    echo "[Desktop Entry]" | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo "Type=Application" | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo "Name=jupyterlab" | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo 'Exec=bash -c '"'"'source ~/.virtualenvs/sb3/bin/activate && jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP "(?<=src )\S+") --no-browser --allow-root'"'"'' | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo >> ${HOME}/.bashrc
    echo "source ~/.virtualenvs/sb3/bin/activate" >> ${HOME}/.bashrc
    echo "if ! jupyter lab list | grep -q 'http' ; then" >> ${HOME}/.bashrc
    echo '	jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP "(?<=src )\S+") --no-browser --allow-root &' >> ${HOME}/.bashrc
    echo "fi" >> ${HOME}/.bashrc
    echo "deactivate" >> ${HOME}/.bashrc
}

make_swapfile()
{
    sudo fallocate -l 4G /var/swapfile
    sudo chmod 600 /var/swapfile
    sudo mkswap /var/swapfile
    sudo swapon /var/swapfile
    sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
}

write_boot_script_step2()
{
    echo "$SCRIPTPATH -2 $OPTIONS" >> ~/.bashrc
}

write_boot_script_step3()
{
    echo "$SCRIPTPATH -3 $OPTIONS" >> ~/.bashrc
}

remove_boot_script()
{
    sed -i '$ d' ~/.bashrc
}

main()
{
    OPTIONS=$(getopt -o 123h --long pytorch,torchvision,tensorflow,jupyterlab -n "$0" -- "$@")

    eval set -- "$OPTIONS"

    echo " [  Jetson Nano Setup v0.1  ]"
	
    INSTALL_STEP=0
    while true; do
        case "$1" in 
            -1) 
                if [ "$INSTALL_STEP" -le "1" ]
                then 
                    INSTALL_STEP=1 
                fi
                ;;
            -2) 
                if [ "$INSTALL_STEP" -le "2" ]
                then 
                    INSTALL_STEP=2 
                fi
                ;;
            -3) 
                if [ "$INSTALL_STEP" -le "3" ]
                then 
                    INSTALL_STEP=3 
                fi
                ;;
            -- ) break ;;
        esac
        shift
    done

    if [ "$INSTALL_STEP" -eq "0" ] ; then
        INSTALL_STEP=1
    fi

    case $INSTALL_STEP in
        1)
            echo "Setting up step 1.."
            setup_step1 && write_boot_script_step2 && sudo reboot
            ;;
        2) 
            echo "Setting up step 2.."
            remove_boot_script && setup_step2 && write_boot_script_step3 && sudo reboot
            ;;
        3)
            echo "Setting up step 3.."
            remove_boot_script && setup_step3 && sudo reboot
            ;;
    esac
}

main $@
exit 0