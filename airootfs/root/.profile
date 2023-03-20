#!/usr/bin/bash

if [ ! -d "/root/archinstall" ]; then
	git clone https://github.com/archlinux/archinstall
fi

if [ ! -d "/root/fgbox" ]; then
	git clone https://github.com/phytoporg/fgbox
fi

cp fgbox/src/install/fgbox_installer.py archinstall/examples
cd archinstall && python -m pip install .
cd -

pacman-key --init
pacman-key --populate archlinux
python -m archinstall --config ./fgbox/data/archinstall.json --disk_layout ./fgbox/data/archinstall_disk.json --script fgbox_installer
