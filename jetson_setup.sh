#!/bin/bash

password=$USER

SCRIPTPATH="$(realpath $0)"

setup_step1()
{
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* -y
    sudo -S apt clean -y && sudo -S apt autoremove -y
    sudo apt install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev libopenblas-base liblapack-dev  
    sudo apt install -y libatlas-base-dev gfortran libfreetype6-dev build-essential libopenmpi-dev libblas-dev libpng-dev
    sudo apt install -y nano htop python3-pip python3-dev python3-smbus cmake
    if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then
        echo "** Add CUDA stuffs into ~/.bashrc"
        echo >> ${HOME}/.bashrc
        echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
    fi
}

setup_step2()
{
    python3 -m pip install -U pip testresources setuptools protobuf
    python3 -m pip install flask
    python3 -m pip install -U numpy==1.19.4
    python3 -m pip install pillow==8.4.0
    python3 -m pip install matplotlib==3.3.4
    python3 -m pip install pandas==1.1.5
    python3 -m pip install scipy==1.5.3
    python3 -m pip install cython
    python3 -m pip install scikit-learn==0.22.0
    python3 -m pip install seaborn==0.10.1
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
    python3 -m pip install -U h5py traitlets 
    python3 -m pip install -U Jetson.GPIO pyserial
    sudo -H pip3 install -U jetson-stats==3.1.4
    sudo apt install -y virtualenv
    sudo adduser $USER dialout
    sudo systemctl restart jetson_stats.service
}

setup_step3()
{
    sudo apt install -y nodejs npm
    python3 -m pip install -U jupyter jupyterlab
    setup_jupyterlab
    install_SB3
    make_swapfile
    switch_to_lubuntu
    sudo -S apt clean -y && sudo -S apt autoremove -y
}

setup_jupyterlab()
{
    python3 -m jupyterlab --generate-config
    python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
    sudo bash -c "echo \"[Desktop Entry]\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Name=jupyterlab\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Exec=python3 -m jupyterlab --ip=$(ip -o route get 8.8.8.8 | grep -oP '(?<=src )\S+') --no-browser --allow-root\" >> /etc/xdg/autostart/jupyterlab.desktop"
}

install_SB3()
{
    python3 -m virtualenv -p python3 ~/.virtualenvs/sb3 --system-site-packages
    source ~/.virtualenvs/sb3/bin/activate
    wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    pip install -U torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    pip install -U stable-baselines3==1.3.0
    rm torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    python3 -m ipykernel install --user --name=sb3
    deactivate
    sudo echo "alias sb3='source ~/.virtualenvs/sb3/bin/activate'" >> /home/$USER/.bashrc
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