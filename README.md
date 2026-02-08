# Practical Autoinstall Example for Ubuntu Server/Desktop

Example of functional simple and complex autoinstall.yaml files for hands-free flashing of computers with Ubuntu 24.04+ Server and/or Desktop.

Shell script that can build a custom ISO image based on a standard Ubuntu Desktop/Server ISO but inserts autoinstall.yaml and optionally, modified the grub kernel command line to have completely hands-free OS installation (no user prompt at all).

References:
- Script extends some work from here: https://www.youtube.com/watch?v=ibvxiybT96M
- Script is heavily modified from here: https://github.com/covertsh/ubuntu-autoinstall-generator

## Prerequisites
To use [`ubuntu-autoinstall-iso-generator.sh`](./ubuntu-autoinstall-iso-generator.sh), ensure you have installed these prerequisite packages.

```bash
sudo apt update
sudo apt install xorriso 7zip
```

## Usage
To generate a new a custom ISO image with an `autoinstall.yaml` or cloudinit file, use the following script.

```bash
Usage:
  ubuntu-autoinstall-iso-generator.sh [OPTIONS]

Summary:
  Create a custom Ubuntu Desktop or Server ISO with an embedded autoinstall
  configuration. The resulting ISO will automatically provision a system
  using Subiquity when booted.

  This script supports Ubuntu:
    - Desktop 24.04 and newer
    - Server 22.04 and newer (24.04+ recommended)

Required options:
  -a, -u, --autoinstall, --user-data FILE
        Path to an autoinstall-compatible cloud-init user-data file.
        This file will be copied into the ISO root as:
            /autoinstall.yaml

  -s, --source FILE
        Path to the original Ubuntu ISO (Desktop or Server).
        The ISO is extracted, modified, and repackaged.

Optional options:
  -d, --destination FILE
        Output path for the generated ISO.
        Defaults to:
            ./custom.iso
        Existing files will be overwritten.

  --unattended, --hands-free
        Modify GRUB boot entries to automatically start autoinstall
        without requiring user interaction at the boot menu.

        Without this flag:
          - Subiquity will detect autoinstall.yaml
          - A confirmation prompt may still appear

        With this flag:
          - Autoinstall starts immediately on boot

  --dry-run
        Perform input validation and print planned actions,
        but do not extract the ISO, modify files, or repackage.
        Exits successfully without side effects.

  -h, --help
        Show this help text and exit.

Behavior notes:
  - The autoinstall file is embedded directly at the ISO root.
    No NoCloud seed directory is required.
  - The resulting ISO boots in both BIOS and UEFI modes.
  - This script is suitable for imaging physical machines and VMs.

Examples:
  Build a custom unattended ISO:
    ubuntu-autoinstall-iso-generator.sh \
      --source ubuntu-24.04-live-server-amd64.iso \
      --autoinstall autoinstall.yaml \
      --destination ubuntu-autoinstall.iso \
      --unattended

  Validate inputs without modifying anything:
    ubuntu-autoinstall-iso-generator.sh \
      --source ubuntu-24.04-desktop-amd64.iso \
      --autoinstall autoinstall.yaml \
      --dry-run
```


For help, run
```bash
./ubuntu-autoinstall-iso-generator.sh -h|--help
```

Example usage for basic custom ISO without modifying grub. It just puts `autoinstall.yaml` into the root dir of the ISO. When putting the ISO on a USB and attempting to install on a new computer, clicking `Try and install Ubuntu` will eventually kick off the subiquity service that will autodetect the `autoinstall.yaml` in the ISO and begin the cloud init process. The user will be prompted `yes/no` to continue the autoinstall process after a bit:
```bash
./ubuntu-autoinstall-iso-generator.sh --autoinstall ./dev_autoinstall_desktop.yml --source /path/to/downloaded/source/iso/ubuntu-24.04.3-desktop-amd64.iso --destination ./desktop_test.iso
```
For example, 
![autoinstall prompt](./assets/ubuntu_autoinstall_prompt.png) 


Example usage for completely hands-free installation, no prompting at all except initial grub menu selection (use with caution). We can completely bypass the prompt from the above image by doing what the message suggests, adding "autoinstall" to the grub kernel command line. This is done internally in the script by extracting the original ISO contents, modifying `boot/grub.cfg` to include "autoinstall", and constructing a new ISO with the modified grub file:
```bash
./ubuntu-autoinstall-iso-generator.sh --autoinstall ./dev_autoinstall_server.yml --source /path/to/downloaded/source/iso/ubuntu-24.04.3-live-server-amd64.iso --destination ./server_test.iso --unattended
```
This script is modified from here: https://github.com/covertsh/ubuntu-autoinstall-generator

I removed all the ridiculous emojis, added pythonic loguru style logging, and updated grub menu manipulation to work on Ubuntu 24.04, Ubuntu 25.04, and (hopefully) later. I tested the resulting ISOs for Server/Desktop in VirtualBox VMs and on my personal laptop.


## Discussion/Explanation

There are numerous ways to use Ubuntu's new autoinstall/cloud-init feature each varying on levels of hands-free-ness.

TODO

## Debugging/Testing

Testing OS flashing on hardware can be a very time consuming processing, especially when trying to test system-wide configurations from a single file like the new autoinstall/cloud-init framework.

As such, debugging repeatedly in software using virtual machines helps iterate the OS flashing process much faster.

There's a few ways to prepare a bootable USB.
1. Assuming you have installation media (a USB stick) with Ubuntu Desktop 24.04 on it. Simply drop this file onto the highest level directory of the USB. I was able to do this on Windows but on Linux the USB was "readable-only" so I couldn't do this
2. Create a custom ISO with the autoinstall inside it and then create a bootable USB from that (with `dd` or other tools)


TODO. Requires more prefacing here.
Initiate the install process on the new machine and step through the setup. When you get to the Installation page, select the `autoinstall` option and choose to boot from a file. Provide the path to the autoinstall file like so `file:///<name of autoinstall.yml>` and validate the install.

If formed properly, the entire system should be up and running in about 15 minutes with all your favorite packages and (most) settings already configured!

### Testing with VirtualBox

1. Install VirtualBox
2. If on Linux, you may encounter this error and may need to run this
    ```bash
    lsmod | grep kvm
    # Validat output and you'll probably need to run these
    sudo modprobe -r kvm_intel
    sudo modprobe -r kvm
    ```
3. See the modified `ubuntu-autoinstall-iso-generator.sh` to generate a custom ISO image with the autoinstall embedded and set that as the optical disk to boot from when testing with VirtualBox VMs.
4. If you're testing installation from scratch, I'd recommend creating a new Hard Disk and assigning that to the SATA Port. You can delete old disks by first detaching the disk you want to remove from all jobs that use it. Then go to the media tab on the left, select the disk, and then click the button at the top that says delete. This will delete the disk and free up space on you computer and then you can create a new one there.
5. Once created, reattach the disk and this is equivalent to wiping the SSD for your virtual pc. This allows you to test the autoinstall process an arbitrary number of times. A little tedious but it's much faster than testing on real hardware.


Recommended configurations for VirtualBox Testing
![VirtualBox Server Configuration](./assets/virtualbox_server_configuration.png) 

![VirtualBox Desktop Configuration](./assets/virtualbox_desktop_configuration.png) 

Configuration for server ISO:
- CPU: 4 cores
- RAM: 2048 MB
- Storage: 10 GB


Configuration for desktop ISO:
- CPU: 8 cores
- RAM: >7000 MB (if it's too low, the process is too slow and freezes up regularly)
- Storage: 25 GB

Test on Ubuntu 24.04.3 Server AND Desktop with VirtualBox 7.2.4 

