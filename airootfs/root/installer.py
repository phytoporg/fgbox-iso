#!/usr/bin/python3

import archinstall
from archinstall import User

ADDITIONAL_PACKAGES=[
    # X
    "xorg",
    "xorg-xinit",
    "xterm",

    # gfx
    "mesa",
    "xf86-video-intel",

    # audio
    "alsa-utils",
    "alsa-tools",

    # dev
    "vim",
    "python",
    "archinstall",

    # gaming for gamers
    "ttf-liberation",
    "steam",

    # virtualization (REMOVEME)
    "hyperv",
    "open-vm-tools",
    "qemu-guest-agent",
    "virtualbox-guest-utils-nox",

    # network
    "networkmanager",
]

if archinstall.arguments.get('help', None):
    archinstall.log(' - Optional filesystem type via --filesystem=<fs type>')
    archinstall.log(' - Optional systemd network via --network')
    archinstall.log()

archinstall.arguments['harddrive'] = archinstall.select_disk(archinstall.all_blockdevices())
if archinstall.arguments['harddrive']:
    archinstall.arguments['harddrive'].keep_partitions = False

    print(f"Formatting {archinstall.arguments['harddrive']} in ", end='')
    with archinstall.Filesystem(archinstall.arguments['harddrive'], archinstall.GPT) as fs:
        # Use the whole disk
        if archinstall.arguments['harddrive'].keep_partitions is False:
            fs.use_entire_disk(root_filesystem_type=archinstall.arguments.get('filesystem', 'btrfs'))

        boot = fs.find_partition('/boot')
        root = fs.find_partition('/')

        boot.format('fat32')
        root.format(root.filesystem)
        root.mount('/mnt')
        boot.mount('/mnt/boot')

with archinstall.Installer('/mnt') as installation:
    if installation.minimal_installation(multilib=True):
        installation.set_hostname('arch-fgbox')
        installation.add_bootloader()
        installation.copy_iso_network_config(enable_services=True)

        installation.add_additional_packages(ADDITIONAL_PACKAGES)
        installation.install_profile('minimal')

        # Linksys router security model for now :P
        user_sudo = True
        admin_user = User('admin', 'password', user_sudo)
        installation.user_create(admin_user)
