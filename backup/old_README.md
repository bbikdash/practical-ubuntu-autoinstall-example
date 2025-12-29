

Useful Links:
- https://dustinspecker.com/posts/ubuntu-autoinstallation-virtualbox/
- https://ubuntu.com/tutorials/how-to-run-ubuntu-desktop-on-a-virtual-machine-using-virtualbox#3-install-your-image
- https://gist.github.com/bitsandbooks/6e73ec61a44d9e17e1c21b3b8a0a9d4c
- https://documentation.ubuntu.com/public-images/public-images-how-to/run-an-ova-using-virtualbox/
- https://serverfault.com/questions/1031271/ubuntu-server-auto-install
- https://github.com/jjbailey/ubuntu-autoinstall


```
# 1. Stop any running VMs and close VirtualBox
# 2. Remove VirtualBox packages and config files
sudo apt purge virtualbox virtualbox-*

# 3. Clean up residual dependencies (optional but recommended)
sudo apt autoremove

# 4. Delete leftover Virtual Machine files (this deletes your VMs!)
rm -rf ~/VirtualBox\ VMs
rm -rf ~/.config/VirtualBox/
```

From Gemini:
To modify GRUB for Ubuntu Autoinstall, you typically edit the  within a custom ISO or add kernel parameters via  to point the installer to your configuration, using parameters like  for local setups or serving the YAML over HTTP; the goal is to pass boot arguments to the kernel that trigger  (the installer) to load your cloud-init/autoinstall config from a specified source. [1, 2, 3, 4]
Methods for GRUB Modification 
1. Editing  (for custom ISOs) This involves modifying the bootloader menu entries directly when building a custom install ISO. 

• Extract ISO: Mount and extract the original ISO contents. 
• Add : Place your  (and ) files in a  directory within the extracted files (e.g., ). 
• Modify : Edit the  file (often in ) to add or change a menu entry: 
• Repackage: Rebuild the ISO with  or  to include your changes. [1, 4, 6]  

2. Kernel Parameters for Live Boot (Temporary/Testing) For quick tests, interrupt GRUB on boot and press  to edit the  line, adding autoinstall parameters. 

• Add : Append  to the kernel line. 
• Specify Data Source: Add  (e.g., ) to tell it where to find your config. [2, 7]  

3. Using  for GRUB Configuration (Advanced) You can instruct the installer to modify GRUB after the initial boot or during the process. 

• : Use  in your  to run scripts before installation begins, like fetching configuration or pausing for manual checks. 
• : Execute commands to modify GRUB after installation, but before final reboot, using  or direct file edits. [7, 8]  

Key Autoinstall Parameters in  

• : Sets hostname, username, and password. 
• : Lists packages to install. 
• : Defines disk layout (LVM, GPT, wiping). 
• : Configures network settings using Netplan. 
• : Sets system locale. [1, 6, 7, 9, 10]  

Example  snippet for Local Setup 

AI responses may include mistakes.

[1] https://medium.com/@Phoenixforge/getting-your-feet-wet-with-ubuntu-autoinstall-e2c012454a37
[2] https://askubuntu.com/questions/1442717/pass-parameters-to-autoinstall
[3] https://canonical-subiquity.readthedocs-hosted.com/en/latest/howto/autoinstall-quickstart.html
[4] https://serverfault.com/questions/1146304/how-to-remaster-an-ubuntu-live-iso-to-revise-grub-cfg-to-autoinstall-from-local
[5] https://documentation.ubuntu.com/real-time/latest/how-to/modify-kernel-boot-parameters/
[6] https://linuxconfig.org/how-to-repackage-an-ubuntu-iso-image-for-autoinstall-using-yaml
[7] https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html
[8] https://askubuntu.com/questions/281119/how-do-you-run-update-grub
[9] https://linuxconfig.org/how-to-write-and-perform-ubuntu-unattended-installations-with-autoinstall
[10] https://www.youtube.com/watch?v=ibvxiybT96M

