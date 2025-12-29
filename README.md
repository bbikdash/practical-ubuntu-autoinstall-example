# Practical Autoinstall Example for Ubuntu Desktop

Example of functional simple and complex autoinstall.yaml files for hands-free flashing of computers with Ubuntu 24.04 Server and/or Desktop.

Shell script that can build a custom ISO image based on a standard Ubuntu Desktop/Server ISO but inserts autoinstall.yaml and optionally, modified the grub kernel command line to have completely hands-free OS installation (no user prompt at all).

## Prerequisites
To use [`ubuntu-autoinstall-iso-generator.sh`](./ubuntu-autoinstall-iso-generator.sh), ensure you have installed these prerequisite packages.

```bash
sudo apt update
sudo apt install xorriso
```

## Usage

To generate a new modified ISO

For help
```bash
./ubuntu-autoinstall-iso-generator.sh -h|--help
```

Example usage for basic custom ISO without modifying grub. It just puts `autoinstall.yaml` into the root dir of the ISO:
```bash
./ubuntu-autoinstall-iso-generator.sh --autoinstall ./dev_autoinstall_desktop.yml --source /path/to/downloaded/source/iso/ubuntu-24.04.3-desktop-amd64.iso --destination ./desktop_test.iso
```

Example usage for completely hands-free installation, no prompting at all except initial grub menu selection(use with caution):
```bash
./ubuntu-autoinstall-iso-generator.sh --autoinstall ./dev_autoinstall_server.yml --source /path/to/downloaded/source/iso/ubuntu-24.04.3-live-server-amd64.iso --destination ./server_test.iso --unattended
```
This script is modified from here: https://github.com/covertsh/ubuntu-autoinstall-generator

I removed all the ridiculous emojis, added pythonic loguru style logging, and updated grub menu manipulation to work on Ubuntu 24.04 and (hopefullly) later. I tested the resulting ISOs for Server/Desktop in VirtualBox VMs and on my personal laptop.


## Discussion/Explanation



## Debugging/Testing

There are numerous ways to use Ubuntu's new autoinstall/cloud-init feature each varying on levels of hands-free-ness




Assuming you have installation media (a USB stick) with Ubuntu Desktop 24.04 on it. Simply drop this file onto the highest level directory of the USB.

Initiate the install process on the new machine and step through the setup. When you get to the Installation page, select the `autoinstall` option and choose to boot from a file. Provide the path to the autoinstall file like so `file:///<name of autoinstall.yml>` and validate the install.

If formed properly, the entire system should be up and running in about 15 minutes with all your favorite packages and (most) settings already configured!

## Testing with VirtualBox

1. Install VirtualBox
2. If on Linux

3. See the modified `ubuntu-autoinstall-iso-generator.sh` which is a modification

Configuration for server ISO:
- CPU: 4 cores
- RAM: 2048 MB
- Storage: 10 GB
Configuration for desktop ISO:
- CPU: 8 cores
- RAM: >7000 MB (if it's too low, the process is too slow and freezes up regularly)
- Storage: 25 GB

Test on Ubunt 24.04.3 Server AND Desktop with VirtualBox 7.2.4 

