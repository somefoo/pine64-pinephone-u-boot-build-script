#! /bin/bash

sudo apt install build-essential bison flex swig gcc-aarch64-linux-gnu libssl-dev

git clone https://github.com/crust-firmware/arm-trusted-firmware/
cd arm-trusted-firmware
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64
make PLAT=sun50i_a64 -j$(nproc) bl31
cd ..

git clone https://gitlab.com/pine64-org/u-boot.git
cd arm-trusted-firmware
cp build/sun50i_a64/release/bl31.bin ../u-boot/
cd ..

FILE=or1k-linux-musl-cross.tgz
if [ -f "$FILE" ]; then
    echo "$FILE exists. No download required."
		tar zxvf or1k-linux-musl-cross.tgz
else 
    echo "$FILE does not exist. Downloading..."
		wget https://musl.cc/or1k-linux-musl-cross.tgz
		tar zxvf or1k-linux-musl-cross.tgz
fi

ORPATH=$(pwd)/or1k-linux-musl-cross/bin/
export PATH="$PATH:$ORPATH"

git clone https://github.com/crust-firmware/crust
cd crust
export CROSS_COMPILE=or1k-linux-musl-
make pinephone_defconfig
make -j$(nproc) scp
cp build/scp/scp.bin ../u-boot/
cd ..

cd u-boot/
git checkout crust
export CROSS_COMPILE=aarch64-linux-gnu-
export BL31=bl31.bin
export ARCH=arm64
export SCP=scp.bin
make distclean
make pinephone_defconfig
make all -j$(nproc)

echo "Done!"
echo "Copy to device now, for example:"
echo "  sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/[CHANGE THIS] bs=1024 seek=8"
echo "The eMMC on the Pinephone is normally: /dev/mmcblk2"

echo "To change the RAM speed, edit: u-boot/configs/pinephone_defconfig"
echo "  and run this script again, make sure to use multiples of 24."
