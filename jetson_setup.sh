#!/bin/bash

password=$USER

SCRIPTPATH="$(realpath $0)"

setup_step1()
{
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* -y
    sudo -S apt clean -y && sudo -S apt autoremove -y
    sudo apt install -y nano curl htop python3-pip python-pip
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
    if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then
        echo "** Add CUDA stuffs into ~/.bashrc"
        echo >> ${HOME}/.bashrc
        echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
    fi
    echo "OPENBLAS_CORETYPE=ARMV8" >> ${HOME}/.bashrc
}

setup_step2()
{
    setup_gpio_and_comms
    cd ~
    mkdir -p install
    cd install 
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-pypy3-Linux-aarch64.sh .
    chmod a+x Mambaforge-pypy3-Linux-aarch64.sh
    ./Mambaforge-pypy3-Linux-aarch64.sh
}

setup_gpio_and_comms()
{
    sudo -H pip3 install -U jetson-stats==3.1.4
    sudo systemctl restart jetson_stats.service
    sudo pip3 install -U Jetson.GPIO pyserial
    sudo adduser $USER dialout
}

setup_step3()
{
    mamba config --set auto_activate_base false
    sudo apt install -y python3-h5py libhdf5-serial-dev hdf5-tools libpng-dev libfreetype6-dev
    mamba create -y -n sb3 python=3.6
    mamba install -n sb3 -y matplotlib pandas numpy pillow scipy tqdm scikit-image scikit-learn seaborn cython h5py jupyter ipywidgets -c conda-forge
    install_SB3
    setup_jupyterlab
    make_swapfile
    switch_to_lubuntu
    sudo -S apt clean -y && sudo -S apt autoremove -y
}

setup_install_folder()
{
    if [ ! -d ~/install ]
    then
        mkdir -p ~/install
    fi
    cd ~/install
    eval "$(conda shell.bash hook)"
    mamba activate sb3
}

teardown_install_folder()
{
    mamba deactivate
}

install_SB3()
{
    setup_install_folder
    wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    sudo apt-get install -y libopenblas-base libopenmpi-dev
    pip install torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    mamba install -n sb3 -y stable-baselines3==1.3.0 -c conda-forge
    teardown_install_folder
}

setup_jupyterlab()
{
    setup_install_folder
    mamba install -y jupyterlab
    jupyter lab --generate-config
    python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
    jetsonip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(192.([0-9]*\.){2}[0-9]*).*/\2/p'`
    sudo bash -c "echo \"[Desktop Entry]\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Name=jupyterlab\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Exec=jupyter lab --ip=$jetsonip --no-browser --allow-root\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo echo "alias sb3='mamba activate sb3'" >> /home/$USER/.bashrc
    teardown_install_folder
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