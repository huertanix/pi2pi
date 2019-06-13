# pi2pi
A self-contained network between two Raspberry Pis

Overview
========

This installation is made up of two Raspberry Pis, one, named rpa.local, acting as a DHCP server using `dnsmasq`, the other, rpb.local, as a client. Both devices have a bash script in the default `pi` user directory called imagesync.sh. This script is ran automatically every minute by a cron job listed in the cron tab for the same `pi` user. The script copies images in a `/sending` directory in the USB drive attached to it, and uses rsync to copy everything in that directory into a directory and USB drive with the same name attached on the other device. The script checks the local hostname, either `rpa.local` or `rpb.local` and chooses the destination to send it to that isn't itself; e.g. the script will check if it's running on rpa.local and set the destination to rpb.local. Behind the scenes, rpa.local maps to 10.0.0.1 and rpb.local uses 10.0.0.49. Each device is set up to connect via SSH using public key authentication, so no manual intervention is needed to enter a password when rsync is copying files over ethernet.

Preparing USB Drives
====================

Two USB drives should be configured as plain FAT32 drives. The partitioning scheme should not matter so much, but the drives used in testing used a Master Boot Record partitioning scheme. Within each drive, there should be two directories:

    /sending
    /receiving

The `sending` dirtectory should include images that will be copied automatically to the other Pi’s USB drive’s `receiving` directory, so nothing should be put in `receiving`.

The drive name should be identical for both USB drives and not include any spaces. Case sensitivity should not matter but just in case that changes in future versions, keep both drive’s names in a matching case.

There’s no limitations on the type of files that can be copied over; It can be images, text files, video, etc. There are no constraints on filenames as long as they confirm to the limits of FAT32 file names.

Addressing a Corrupted or Extinguished Drive
--------------------------------------------

USB Drives have a limited shelf life, depending on their quality of hardware, storage available, frequency of use, or sometimes even by the host computer (in this case, a Raspberry Pi) being powered down the otherwise perfectly reasonable way: Unplugging it. If a USB drive becomes corrupted, either replace it and prepare a new one or try to patch it with the `fsck` command. From a Pi connected to a TV/keyboard/mouse and the effected USB drive connected, run:

$`umount /dev/sda1`

and then run:

$`sudo fsck -Cy /dev/sda1`

Finally, restart or shut down the Pi from the shutdown menu.

Cloning From an Existing MicroSD Card
=====================================
This installation is made up of two Raspberry Pis with two different configurations. The "brain" of a Raspberry Pi lives in its MicroSD card. To clone one of them, you'll need to acquire another Pi with a new MicroSD card. An existing rpa MicroSD card will be needed to clone another rpa, and an existing rpb MicroSD card will be needed to clone another rpb. The current setup is designed to fit within a 4GB MicroSD card.

Instructions for cloning this or any Raspberry Pi MicroSD card to a new MicroSD card are here: https://appcodelabs.com/how-to-backup-clone-a-raspberry-pi-sd-card-on-macos-the-easy-way.

Starting from Scratch
=====================

If no existing Pi2Pi installation is available and there's a need to build a new installation from scratch, follow these instructions:

Installing Raspbian
-------------------

Each Pi will need Raspbian Linux installed on an SD card. Raspbian 2018-11-13 (Full) is the version of Raspbian used since, although a full desktop isn’t necessary for this installation, this version is set up to automatically mount any compatible USB drives. The Raspbian .img file will need to be installed on two microSD cards: one for rpa, and one for rpb. Balena Etcher (https://www.balena.io/etcher/) can be used to write the .img image to each microSD card. This version of Raspbian will need a microSD card that is at least 4GB in size, and newer versions may need cards that hold more than that.

One first boot, each Pi will prompt you to have a locale set (Country: US, Language: American English, Timezone: New York, Use US keyboard). Next, it will ask for a password to be created. Although this Pi will not connect to the internet in a live production environment, it will need to connect to the internet at the beginning of the setup to install some software updates, so a good passphrase is recommended here. Finally, you’ll be prompted to connect to a network (this can be a Wi-FI network or an internet-enabled ethernet connection) which you’ll want to do for the aforementioned software updates, and then you’ll be asked update software, which you should do. After updates are complete, follow the prompt to reboot the Pi.

Configuring Hostname
--------------------

From the Raspberry Pi config menu, you’ll want to change the hostname to “rpa.local” for the rpa Pi, and “rpb.local” for the rpb Pi.

Alternatively, if you’re configuring this Pi through a serial console instead of having it connected to a display, mouse and keyboard, you can also change the hostname from the command line with these instructions: https://geek-university.com/raspberry-pi/change-raspberry-pis-hostname/.

Configuring DNSmasq
-------------------

To simplify things for rpb, there’s no special configuration needed on the client end, since Raspbian is already configured to look for an IP address from a DHCP server by default. To keep the IP address of rpb consistent across DHCP leases however, we’ll want to know its ethernet Media Access Control (MAC) address before configuring rpa.

From rpb:

Open up a terminal and look for the MAC address:

    ifconfig eth0

Look for the colon-delimitated string after "Ethernet HWaddr”; It should look something similar to "b7:30:cf:f1:7d:b4”.

A good guide on finding your Pi’s MAC address with some examples and an explaination of what ifconfig’s output means can be found here: http://www.robert-drummond.com/2013/05/23/how-to-find-the-mac-address-of-your-raspberry-pi/.

After you write down or take a photo of rpb’s MAC address, go to rpa.

From rpa:

Connect to the internet, either with the ethernet connection or Wi-Fi from the Raspbian desktop.

Install dnsmasq:

    sudo apt install dnsmasq

After dnsmasq is installed, turn off Wi-Fi from the Raspbian desktop if it was turned on and disconnect the ethernet cable from rpa if that was being used for an internet connection.

Configure the `/etc/dhcpcd.conf` using nano, the text editor that is already installed and ready to use in Raspbian:

    nano /etc/dhcpcd.conf

Use the arrow keys to navigate the cursor to the very end of the file. At the very end, add these lines:

    interface eth0
    static ip_address=10.0.0.1/8
    static domain_name_servers=8.8.8.8,8.8.4.4
    nolink

To save the file, press Control+o, then hit enter since we’re not changing the file name. 

Finally, press Control+x to exit nano

We’ll be creating a new configuration file for dnsmasq rather than editing the existing one. Just in case something goes awry though, copy the existing dnsmasq.conf file to the Pi home directory for safekeeping:

    sudo mv /etc/dnsmasq.conf /home/pi/etc_dnsmasq.conf

The new dnsmasq.conf file is based on one created in this cluster project: https://downey.io/blog/create-raspberry-pi-3-router-dhcp-server/#install-dnsmasq. For convenience, that file is included with these instructions, so you can edit it before copying it to the Pi.

Using a text editor on your computer, open the included dnsmasq.conf file, then find the line that ends with “#rpb”, it should look like:

    dhcp-host=b8:27:eb:00:00:01,10.0.0.49 #rpb

Replace the MAC address after the “=“ and before the “,” with the MAC address taken from rpb earlier. Save the file, then copy it to a USB drive and connect it to rpa.

From rpa:

In the Raspbian desktop, open the USB drive directory and double-click the dnsmasq.conf to open it in a text viewer. Highlight and copy everything in the dnsmasq.conf file. We’ll paste it into the new dnsmasq.conf file for rpa next.

Back in the terminal, create a new dnsmasq file with nano:

    sudo nano /etc/dnsmasq.conf

From the Terminal menu, click Edit -> Paste to load the contents copied from the USB drive copy into the new/empty file in nano. 

To save the file, press Control+o, then hit enter since we’re not changing the file name. 

Finally, press Control+x to exit nano. 

There’s a known bug where some processes start up on Raspbian faster than other processes and cause problems. A hacky fix is to delay the initialization of dnsmasq for a small period of time:

    nano /etc/init.d/dnsmasq

Add these lines after the `#!/bin/sh` line:

    # Hack to wait until dhcpcd is ready
    sleep 10

The first few lines should look like…

    #!/bin/sh

    # Hack to wait until dhcpcd is ready
    sleep 10
    
    ### BEGIN INIT INFO

To save the file, press Control+o, then hit enter since we’re not changing the file name. 

Finally, press Control+x to exit nano.

Shut down rpa, then connect the ethernet cable to rpb.

Turn on rpa, then turn on rpb.

Configuring SSH
---------------

From the Raspberry Pi config menu under the Interfaces tab, you’ll want to switch SSH to Enable. You’ll need to do this on both rpa and rpb. You may need to reboot afterwards for this to take effect.

Settip up key-based authentication unfortunately has to be done from the command line. A good example with screenshots and gifs of the process is here: https://www.tecmint.com/ssh-passwordless-login-using-ssh-keygen-in-5-easy-steps/. The steps for setting this up for two Pis are similar to this example, except that we’ll be using the IP addresses we set up with DNSmasq earlier:

From rpa:

    ssh-keygen -t rsa

Hit enter when asked for the file location and enter for no passphrase. Once the key pair is saved, copy the public key to rpb:

    scp /home/pi/.ssh/id_rsa.pub pi@rpb.local:/home/pi/id_rsa_rpa.pub

You might be warned about this being a new connection. Type yes and enter to recognize the new connection.

Next, go to rpb and do the same.

From rpb:

    ssh-keygen -t rsa

Hit enter when asked for the file location and enter for no passphrase. Once the key pair is saved, copy the public key to rpa:

    scp /home/pi/.ssh/id_rsa.pub pi@rpa.local:/home/pi/id_rsa_rpb.pub

You might be warned about this being a new connection. Type yes and enter to recognize the new connection.

Add rpa’s public key, which was copied to rpb earlier, to rpb’s list of authorized keys:

    cat id_rsa_rpa.pub >> /home/pi/.ssh/authorized_keys

Adjust the permissions on the file and the SSH directory in general:

    chmod 700 /home/pi/.ssh
    chmod 600 /home/pi/.ssh/authorized_keys

Finally, ensure you can connect to rpa:

    ssh pi@rpa.local

If you are able to connect to rpa without having to enter a password this time, great! Before leaving this SSH session, let’s add rpb’s public key to rpa’s list of authorized keys:

    cat /home/pi/id_rsa_rpb.pub >> /home/pi/.ssh/authorized_keys

Adjust the permissions on the file and the SSH directory in general:

    chmod 700 /home/pi/.ssh
    chmod 600 /home/pi/.ssh/authorized_keys

Finally, you can close the rpa session:

    exit

That should be all that’s needed on rpb. If you want to test the script before having it set up to automatically run, ensure both Pis are connected and the USB drives are plugged in, and run the script on _both_ rpa and rpb manually:

    sh /home/pi/imagesync.sh

If it works, you should see the output from `rsync` detailing each file being copied over.

Installing the Script
---------------------

The included imagesync.sh script should be copied from the USB drive to the Pi user’s home directory on both rpa and rpb. It needs to have “execute” permissions for the Pi user in order for the script to be executed.

Fix permissions on imagesync.sh on _both_ rpa and rpb:

    chmod 700 /home/pi/imagesync.sh

The script is pre-configured to use the IP addresses and hostnames we’ve set up earlier, so there’s no need for extra configuration for it. Since this is a bash script, no additional programming languages, compilers, linkers, pre-compilers or virtual machines have to be installed for the script’s code to run.

Next, on _both_ rpa and rpb, create a cron job for the script to run automatically. To edit the list of cron jobs:

    crontab -e

You’ll be prompted to choose a text editor. The default Raspbian installation includes nano, so that’s what I would recommend choosing.

Use the arrow keys to move the cursor to the very last line and add this line, which will tell cron to run this script every minute forever.

    * * * * * /home/pi/imagesync.sh

To save the file, press Control+o, then hit enter since we’re not changing the file name. 

Finally, press Control+x to exit nano. Cron should automatically begin running the imagesync script every minute.

License
=======

Unless otherwise noted, this software is distributed under the GPL v3 License. See LICENSE for further details.
