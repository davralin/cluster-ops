# amd64

````bash
destination_disk=/dev/sda
talos_version=v1.2.4


wget https://github.com/talos-systems/talos/releases/download/${talos_version}/nocloud-amd64.raw.xz
wipefs -af $destination_disk
xzcat nocloud-*64.raw.xz | dd of=${destination_disk} bs=1M

````

# arm64

````bash
apt update && apt install qemu-utils -y

talos_version=v1.2.4
mkdir /tmp/temp && mount -t tmpfs tmpfs /tmp/temp/ && cd /tmp/temp
wget https://github.com/talos-systems/talos/releases/download/${talos_version}/oracle-arm64.qcow2.xz
xz -d oracle-arm64.qcow2.xz
qemu-img convert -f qcow2 -O raw oracle-arm64.qcow2 oracle-arm64.img
wipefs --all --force /dev/sda1
wipefs --all --force /dev/sda15
wipefs --all --force /dev/sda
sync
echo 3 > /proc/sys/vm/drop_caches
dd if=oracle-arm64.img of=/dev/sda bs=1M status=progress
sync
echo 3 > /proc/sys/vm/drop_caches

````

