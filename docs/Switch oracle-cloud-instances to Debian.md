# Switch oracle-cloud-instances to Debian


Credits for this page:
 - https://sj14.gitlab.io/post/2021/01-30-free-k8s-cloud-cluster/
 - https://serverfault.com/questions/528075/is-it-possible-to-on-line-shrink-a-ext4-volume-with-lvm

## Resize rootfs without LVM

1. Create a ubuntu-instance
2. Connect to the node, using `ubuntu` as the username, become root.
3. Add the following files, make them executable, and rebuild initramfs.

`/etc/initramfs-tools/hooks/resizefs`
```
#!/bin/sh

set -e

PREREQS=""

prereqs() { echo "$PREREQS"; }

case $1 in
    prereqs)
        prereqs
        exit 0
    ;;
esac

. /usr/share/initramfs-tools/hook-functions

copy_exec /sbin/e2fsck
copy_exec /sbin/resize2fs

exit 0
```
`/etc/initramfs-tools/scripts/local-premount/resizefs`
```
#!/bin/sh

set -e

PREREQS=""

prereqs() { echo "$PREREQS"; }

case "$1" in
    prereqs)
        prereqs
        exit 0
    ;;
esac

# simple device example
/sbin/e2fsck -yf /dev/sda1
/sbin/resize2fs /dev/sda1 6G
/sbin/e2fsck -yf /dev/sda1
```
`chmod +x /etc/initramfs-tools/hooks/resizefs /etc/initramfs-tools/scripts/local-premount/resizefs`

`update-initramfs -u && update-grub`

4. Remove `growpart` and `resizefs` from `/etc/cloud/cloud.cfg`, and reboot.
   ```
   Filesystem      Size  Used Avail Use% Mounted on
   /dev/sda1       5.8G  1.8G  4.0G  32% /
   ```
5. Run `cfdisk /dev/sda` and resize `sda1` as a partition with 10GB, resize rootfs with `resize2fs /dev/sda1`.
6. You now have a smaller root-fs.

### Debootstrap debian on amd64

1. apt update && apt install debootstrap -y
2. cfdisk /dev/sda, create a new 6gb partition
3. pvcreate /dev/sda2 && vgcreate base /dev/sda2 && lvcreate -L5G base --name root
4. mkfs.ext4 /dev/mapper/base-root -L root -m0 && mount /dev/mapper/base-root /mnt/
5. debootstrap bullseye /mnt http://deb.debian.org/debian
6. mount --bind /dev /mnt/dev; mount --bind /sys /mnt/sys; mount --bind /proc /mnt/proc; cp /etc/fstab /mnt/etc/fstab
7.
````
mkdir -p /mnt/root/.ssh
chmod 0700 /mnt/root/.ssh
cp /home/ubuntu/.ssh/authorized_keys /mnt/root/.ssh/authorized_keys
chmod 0600 /mnt/root/.ssh/authorized_keys
````
8. chroot /mnt
9. apt install ssh sudo python3-simplejson lvm2 -y
10. sed 's/cloudimg-rootfs/root/g' -i /etc/fstab
11.
````
echo 'auto ens3' > /etc/network/interfaces.d/repair
echo 'iface ens3 inet dhcp' >> /etc/network/interfaces.d/repair
systemctl enable systemd-networkd
````
12. mkdir /boot/efi && mount -a
13. `apt install grub-efi-amd64 linux-image-amd64 -y`
14. grub-install /dev/sda && update-grub
15. exit
16. reboot
17. delete ssh-key, and re-connect as root
18. pvcreate /dev/sda1
19. vgextend base /dev/sda1 && pvmove -n root /dev/sda2 /dev/sda1
20. vgreduce base /dev/sda2 && pvremove /dev/sda2
21. fdisk /dev/sda, delete sda2, resize sda1 to 20G
22. reboot
23. pvresize /dev/sda1 && lvresize -r -L20G /dev/base/root

### Debootstrap debian on arm64

1. Create a oracle-linux-instance
2. Connect to the node, using `opc` as the username, become root.
3. Remove swap, and oled-mount from `/etc/fstab` - unmount them or reboot
4. lvremove /dev/ocivolume/oled
5. lvcreate -L8G ocivolume --name debian
6. mkfs.ext4 /dev/mapper/ocivolume-debian -L root -m0 && mount /dev/mapper/ocivolume-debian /mnt/
7. Download dpkg, https://pkgs.org/download/dpkg
( yum install https://download-ib01.fedoraproject.org/pub/epel/8/Everything/aarch64/Packages/d/dpkg-1.20.9-4.el8.aarch64.rpm )
8. Download debootstrap, https://pkgs.org/download/debootstrap ( yum install https://download-ib01.fedoraproject.org/pub/epel/8/Everything/aarch64/Packages/d/debootstrap-1.0.126-1.nmu1.el8.noarch.rpm )
9. debootstrap bullseye /mnt http://deb.debian.org/debian
10. mount --bind /dev /mnt/dev; mount --bind /sys /mnt/sys; mount --bind /proc /mnt/proc; cp /etc/fstab /mnt/etc/fstab
11.
````
mkdir -p /mnt/root/.ssh
chmod 0700 /mnt/root/.ssh
cp /home/opc/.ssh/authorized_keys /mnt/root/.ssh/authorized_keys
chmod 0600 /mnt/root/.ssh/authorized_keys
````
12. chroot /mnt
13. apt install ssh sudo python3-simplejson lvm2 -y
14. Edit /etc/fstab - replace ocivolume-root with ocivolume-debian - also adjust filesystem from xfs to ext4
15.
````
echo 'auto enp0s3' > /etc/network/interfaces.d/repair
echo 'iface enp0s3 inet dhcp' >> /etc/network/interfaces.d/repair
systemctl enable systemd-networkd
````
16. mkdir /boot/efi && mount -a
17. `apt install grub-efi-arm64 linux-image-arm64 -y`
18. grub-install /dev/sda && update-grub
19. exit
20. reboot
21. delete ssh-key, and re-connect as root
22. lvremove /dev/ocivolume/root
23. pvresize --setphysicalvolumesize 20G /dev/sda3
24. cfdisk /dev/sda - create sda4, 10G
25. pvcreate /dev/sda4
26. vgextend ocivolume /dev/sda4 && pvmove -n debian /dev/sda3 /dev/sda4
27. vgreduce ocivolume /dev/sda3 && pvremove /dev/sda3
28. cfdisk /dev/sda, resize sda3 to 20G
29. pvcreate /dev/sda3
30. vgextend ocivolume /dev/sda3 && pvmove -n debian /dev/sda4 /dev/sda3
31. vgreduce ocivolume /dev/sda4 && pvremove /dev/sda4
32. cfdisk /dev/sda, re-create sda4, with remaining space
33. reboot
