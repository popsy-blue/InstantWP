#  Creating the IWPServer qcow2 file

Create a new image using qemu-img, 20G in size:

```text
qemu-img create -f qcow2 iwpserver.img 20G
```

Download the Alpine Version 3.15.0 Virtual iso image:

```text
https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86/alpine-virt-3.15.0-x86.iso
```

Then boot the image using qemu-system-x86_64:

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
Add user 'iwp' to group 'wheel'.

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

and install if any are missing with 
```text
apk add <package name>
```

Copy over the files from folder 'iwpserver 3.0.0' via SFTP.

Add apache2 and mariadb as a startup service.
```text
rc-update add apache2
rc-update add mariadb
```

Download wordpress into the folder /usr/share/webapps/wordpress.

Download filemanager into the folder /user/share/webapps/filemenager.

Create Symlink for folders wordpress and filemanager in /var/www/localhost/htdocs.

Change owner of all files and directories in the /var/www/localhost/htdocs folder to apache/apache.

Reboot.

Create wordpress database in mariadb.

Install wordpress by following the instructions on https://wordpress.org/support/article/how-to-install-wordpress/
```text
http://127.0.0.1:25079/wordpress
```

You are done!

