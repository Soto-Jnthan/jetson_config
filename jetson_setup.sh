#!/bin/bash

password=$USER

SCRIPTPATH="$(realpath $0)"

setup_step1()
{
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* nodejs* -y
    sudo apt install -y nano htop dkms python3-pip libzmq3-dev libffi-dev libssl1.0-dev npm virtualenv
    sudo apt install -y libhdf5-serial-dev hdf5-tools libpng-dev libfreetype6-dev libblas-dev libopenblas-base libopenmpi-dev
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
    if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then 
        echo "** Add CUDA stuffs into ~/.bashrc"
        echo >> ${HOME}/.bashrc
        echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
    fi
    echo >> ${HOME}/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${HOME}/.bashrc
}

setup_step2()
{
    sudo npm cache clean -f
    sudo npm install -g n
    sudo n 16
	create_SB3_env
    sudo -H python3 -m pip install -U jetson-stats==3.1.4
    sudo adduser $USER dialout
    sudo systemctl restart jetson_stats.service
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
    python -m pip install flask 
    python -m pip install -U numpy==1.19.4 
    python -m pip install -U scipy==1.5.3
    python -m pip install -U matplotlib 
    python -m pip install -U Cython packaging Jetson.GPIO pyserial
    python -m pip install jupyterlab
    python -m pip -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python -m pip -U stable-baselines3==1.3.0 tensorboard
    rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python -m ipykernel install --name=sb3
    deactivate
}

install_wifi_drivers()
{
    git clone https://github.com/jeremyb31/rtl8812au-1
    cd rtl8812au-1
    sudo ./dkms-install.sh
    cd ..
    sudo rm -r rtl8812au-1
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
    install_SB3
    make_swapfile
    switch_to_lubuntu
    sudo -S apt clean -y && sudo -S apt autoremove -y
}

setup_jupyterlab()
{
    sb3
    jupyter labextension install @jupyter-widgets/jupyterlab-manager
    jupyter lab --generate-config
    echo "[Desktop Entry]" | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo "Name=jupyterlab" | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo 'Exec=bash -c '"'"'sb3 && jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP "(?<=src )\S+") --no-browser --allow-root'"'"'' | sudo tee -a -i /etc/xdg/autostart/jupyterlab.desktop
    echo >> ${HOME}/.bashrc
    echo "if ! jupyter lab list | grep -q 'http' ; then" >> ${HOME}/.bashrc
    echo '	sb3 && jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP "(?<=src )\S+") --no-browser --allow-root &' >> ${HOME}/.bashrc
    echo "fi" >> ${HOME}/.bashrc
    deactivate
}

make_swapfile()
{
    sudo fallocate -l 4G /var/swapfile
    sudo chmod 600 /var/swapfile
    sudo mkswap /var/swapfile
    sudo swapon /var/swapfile
    sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
}

switch_to_lubuntu()
{
    sudo apt remove --purge ubuntu-desktop -y
    sudo apt remove --purge gdm3 -y
    sudo apt install lxdm -y
    sudo apt install lxde -y
    sudo apt install --reinstall lxdm -y
    sudo sed -i "s|# autologin=dgod|autologin=$USER|g" /etc/lxdm/lxdm.conf
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