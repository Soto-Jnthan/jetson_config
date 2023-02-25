#!/bin/bash

password=$USER

SCRIPTPATH="$(realpath $0)"

setup_step1()
{
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* nodejs* -y
    sudo apt install -y dkms nano htop curl python3-pip build-essential
    sudo apt install -y libhdf5-serial-dev hdf5-tools libpng-dev libfreetype6-dev libblas-dev libopenblas-base libopenmpi-dev
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
    pip3 install --user -U pip testresources setuptools 
    pip3 install --user install flask 
    pip3 install --user install -U numpy==1.19.4 
    pip3 install --user install -U scipy==1.5.3 matplotlib Cython pandas packaging
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
    pip3 install --user install -U traitlets
    pip3 install --user install -U Jetson.GPIO pyserial
    sudo -H pip3 install -U jetson-stats==3.1.4
    sudo apt install -y virtualenv
    sudo adduser $USER dialout
    sudo systemctl restart jetson_stats.service
    install_wifi_drivers	
    install_fan_drivers
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
    sudo apt install libzmq3-dev libffi-dev libssl1.0-dev -y
    sudo apt install npm -y
    sudo npm cache clean -f
    sudo npm install -g n
    sudo n 16
    node -v
    pip3 install --user install jupyterlab
    jupyter labextension install @jupyter-widgets/jupyterlab-manager
    jupyter lab -–generate-config
    python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
    sudo bash -c "echo \"[Desktop Entry]\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Name=jupyterlab\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Exec=jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP '(?<=src )\S+') --no-browser --allow-root\" >> /etc/xdg/autostart/jupyterlab.desktop"
    echo >> ${HOME}/.bashrc
    echo "if ! jupyter lab list | grep -q 'http' ; then" >> ${HOME}/.bashrc
    echo "	jupyter lab --ip=$(ip -o route get 8.8.8.8 | grep -oP '(?<=src )\S+') --no-browser --allow-root &" >> ${HOME}/.bashrc
    echo "fi" >> ${HOME}/.bashrc
}

install_SB3()
{
    python3 -m virtualenv -p python3 ~/.virtualenvs/sb3 --system-site-packages
    source ~/.virtualenvs/sb3/bin/activate
    wget https://nvidia.box.com/shared/static/fjtbno0vp-o676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    pip install -U stable-baselines3==1.3.0 tensorboard
    rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python3 -m ipykernel install --user --name=sb3
    deactivate
    echo "alias sb3='source ~/.virtualenvs/sb3/bin/activate'" >> ${HOME}/.bashrc
}

make_swapfile()
{
    sudo fallocate -l 4G /var/swapfile
    sudo chmod 600 /var/swapfile
    sudo mkswap /var/swapfile
    sudo swapon /var/swapfile
    sudo bash -c 'echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab'
}

install_wifi_drivers()
{
    git clone https://github.com/cilynx/rtl88x2BU_WiFi_linux_v5.3.1_27678.20180430_COEX20180427-5959.git
    cd rtl88x2BU_WiFi_linux_v5.3.1_27678.20180430_COEX20180427-5959
    VER=$(sed -n 's/\PACKAGE_VERSION="\(.*\)"/\1/p' dkms.conf)
    sudo rsync -rvhP ./ /usr/src/rtl88x2bu-${VER}
    sudo dkms add -m rtl88x2bu -v ${VER}
    sudo dkms build -m rtl88x2bu -v ${VER}
    sudo dkms install -m rtl88x2bu -v ${VER}
    sudo modprobe 88x2bu
    cd ..
    sudo rm -r rtl88x2BU_WiFi_linux_v5.3.1_27678.20180430_COEX20180427-5959
}

install_fan_drivers()
{
    git clone https://github.com/Pyrestone/jetson-fan-ctl
    cd jetson-fan-ctl
    sudo ./install.sh
    cd ..
    sudo rm -r jetson-fan-ctl
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