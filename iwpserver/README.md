#  Creating the IWPServer qcow2 file

Create a new image using qemu-img, 20G in size:

```text
qemu-img create -f qcow2 iwpserver.img 20G
```

Download the Alpine Version 3.15.0 Virtual iso image:

```text
https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86/alpine-virt-3.15.0-x86.iso
```

Then boot the image using qemu-system-i386:

```text
./qemu-system-x86_64 \
-m 1024 \
-hda ./iwpserver.img -boot order=cd \
-cdrom ./alpine-virt-3.15.0-x86.iso
-nic user \
, id=iwpnetwork, \
, hostfwd=tcp::25022-:22 \
, hostfwd=tcp::25080-:80 \
, hostfwd=tcp::25021-:21 \
-monitor telnet:127.0.0.1:1234,server,nowait 
```

Install Alpine Linux:

```text
setup-alpine
```

Change the root password to 'root'.

Add a user 'iwp' with password 'iwp'.

To get PHP8, uncomment the community repository in the /etc/apk/repositories file using nano.

Obtain the latest index of available packages and perform update:

```text
apk update
apk upgrade
```

Install apache2, mariadb, mariadb-client, php8 and phpmyadmin with

```text
apk add <package name>
```

Verify if all required php8 packages for wordpress are installed by consulting 
https://make.wordpress.org/hosting/handbook/server-environment/#php-extensions

Copy over the files from 3.0.0 via SFTP.

Change owner of all files and directories in the /var/www/localhost/htdocs folder to apache/apache.

Reboot.



