GET-CimInstance -query "SELECT * from Win32_DiskDrive"
wsl --mount \\.\PHYSICALDRIVEX --bare

lsblk
sudo cryptsetup luksOpen /dev/sdX ehdd_crypt
sudo mkdir -p /mnt/wsl/ehdd-luks
sudo mount /dev/mapper/ehdd_crypt /mnt/wsl/ehdd-luks

sudo umount /mnt/wsl/ehdd-luks
sudo cryptsetup luksClose ehdd_crypt

wsl --unmount \\.\PHYSICALDRIVEX