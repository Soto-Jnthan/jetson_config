#!/bin/bash

password=$1

SCRIPTPATH="$(realpath $0)"

setup_step1()
{
    sudo apt -y update && sudo apt -y upgrade
    sudo apt remove --purge libreoffice* -y
    sudo apt autoremove -y
    sudo apt install -y htop python3-pip python-pip
    sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
    if ! grep 'cuda/bin' ${HOME}/.bashrc > /dev/null ; then
        echo "** Add CUDA stuffs into ~/.bashrc"
        echo >> ${HOME}/.bashrc
        echo "export PATH=/usr/local/cuda/bin\${PATH:+:\${PATH}}" >> ${HOME}/.bashrc
        echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}" >> ${HOME}/.bashrc
        echo "OPENBLAS_CORETYPE=ARMV8" >> ${HOME}/.bashrc
    fi
}

setup_step2()
{
    setup_gpio_and_comms
    cd ~
    mkdir -p install
    cd install
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh .
    chmod a+x Miniforge3-Linux-aarch64.sh
    ./Miniforge3-Linux-aarch64.sh
}

setup_step3()
{
    conda config --set auto_activate_base false
    sudo apt install -y python3-h5py libhdf5-serial-dev hdf5-tools libpng-dev libfreetype6-dev
    conda create -y -n sb3 python=3.6
    conda install -n sb3 -y matplotlib pandas numpy pillow scipy tqdm scikit-image scikit-learn seaborn cython h5py jupyter ipywidgets -c conda-forge
    install_SB3
    setup_jupyterlab
    make_swapfile
    switch_to_lubuntu
    sudo -S apt update
    sudo -S apt clean -y
    sudo -S apt autoremove -y
}

setup_install_folder()
{
    if [ ! -d ~/install ]
    then
        mkdir -p ~/install
    fi
    cd ~/install
    eval "$(conda shell.bash hook)"
    conda activate sb3
}

teardown_install_folder()
{
    conda deactivate
}

install_pytorch()
{
    setup_install_folder
    wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    sudo apt-get install -y libopenblas-base libopenmpi-dev
    pip install torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    teardown_install_folder
}

install_torchvision()
{
    setup_install_folder
    sudo apt-get install -y libjpeg-dev zlib1g-dev libpython3-dev libavcodec-dev libavformat-dev libswscale-dev
    git clone --branch v0.11.1 https://github.com/pytorch/vision torchvision
    cd torchvision
    export BUILD_VERSION=0.11.1
    python setup.py install --user
    teardown_install_folder
}

install_tensorflow()
{
    setup_install_folder
    pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v46 tensorflow
    teardown_install_folder
}

install_jupyterlab()
{
    setup_install_folder
    conda install -y jupyterlab
    teardown_install_folder
}

help()
{
    echo $SCRIPTPATH [-123h] [--pytorch] [--torchvision] [--tensorflow] [--jupyterlab]
}

install_SB3()
{
    setup_install_folder
    wget https://nvidia.box.com/shared/static/fjtbno0vpo676a25cgvuqc1wty0fkkg6.whl -O torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    sudo apt-get install -y libopenblas-base libopenmpi-dev
    pip install torch-1.10.0-cp36-cp36m-linux_aarch64.whl
    conda install -n sb3 -y stable-baselines3==1.3.0 -c conda-forge
    teardown_install_folder
}

setup_jupyterlab()
{
    setup_install_folder
    conda install -y jupyterlab
    jupyter lab --generate-config
    python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
    jetsonip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(192.([0-9]*\.){2}[0-9]*).*/\2/p'`
    sudo bash -c "echo \"[Desktop Entry]\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Name=jupyterlab\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo bash -c "echo \"Exec=jupyter lab --ip=$jetsonip --no-browser --allow-root\" >> /etc/xdg/autostart/jupyterlab.desktop"
    sudo echo "alias sb3='conda activate sb3'" >> /home/$USER/.bashrc
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

setup_gpio_and_comms()
{
    sudo -H pip3 install -U jetson-stats==3.1.4
    sudo systemctl restart jetson_stats.service
    sudo pip3 install -U Jetson.GPIO pyserial
    sudo adduser $USER dialout
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

    if [ "$?" -ne "0" ]
    then
        help
        exit 1
    fi

    eval set -- "$OPTIONS"

    echo " [  Jetson Nano Setup v0.1  ]"

    INSTALL_PYTORCH=false
    INSTALL_TORCHVISION=false
    INSTALL_TENSORFLOW=false
    INSTALL_JUPYTERLAB=false
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
            -h )
                help
                exit 0
                ;;
            --pytorch) 
                INSTALL_PYTORCH=true
                ;;
            --torchvision) 
                INSTALL_TORCHVISION=true
                ;;
            --tensorflow)
                INSTALL_TENSORFLOW=true
                ;;
            --jupyterlab)
                INSTALL_JUPYTERLAB=true
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

    if [ "$INSTALL_PYTORCH" = true ]; then 
        echo "Setting up PyTorch.."
        install_pytorch
    fi

    if [ "$INSTALL_TORCHVISION" = true ]; then 
        echo "Setting up Torchvision.."
        install_torchvision
    fi

    if [ "$INSTALL_TENSORFLOW" = true ]; then 
        echo "Setting up TensorFlow.."
        install_tensorflow
    fi

    if [ "$INSTALL_JUPYTERLAB" = true ]; then 
        echo "Setting up JupyterLab.."
        install_jupyterlab
    fi
}

main $@
exit 0