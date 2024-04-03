# Xiaomi Redmi 4 Pro kernel source

### This is version of source that builds and works just like stock kernel (if anyone need to rebuild stock kernel, but has some problems like wifi not working)

## How to build

1. Clone this repo:
```shell
git clone --depth 1 https://github.com/RuslanUC/android_kernel_xiaomi_markw
```
1. Install build dependencies (this command is for ubuntu):
```shell
apt install -y adb android-sdk-platform-tools git-core ark tar make gnupg flex bc bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip python2 wget abootimg liblzo2-dev python3-pip
```
2. Download and unpack [linaro toolchain 4.9-2017.01](https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/aarch64-linux-gnu/gcc-linaro-4.9.4-2017.01-x86_64_aarch64-linux-gnu.tar.xz)
3. Set CROSS_COMPILE environment variable to `<unpacked linaro path>/bin/aarch64-linux-gnu-`
4. Set ARCH and SUBARCH environment variables to `arm64`
5. Cd to kernel directory
6. (Optional) Make your changes in defconfig / source code
7. Build kernel:
```shell
make clean O=out
make mrproper O=out
make markw_defconfig O=out
make -j8 O=out  # Replace 8 with number of your cpu cores
```
8. Pull your current kernel from device:
```shell
adb shell dd if=/dev/block/mmcblk0p21 of=/sdcard/boot-stock.img
adb pull /sdcard/boot-stock.img ./boot.img
```
9. Unpack it:
```shell
abootimg -x boot.img
```
10. Replace zImage with one you just built:
```shell
rm zImage
cp out/arch/arm64/boot/Image.gz-dtb ./zImage
```
11. Repack boot image:
```shell
abootimg --create new_boot.img -f bootimg.cfg -k zImage -r initrd.img
```
12. Sign wifi kernel module
```shell
scripts/sign-file sha512 out/signing_key.priv out/signing_key.x509 out/drivers/staging/prima/wlan.ko
```
13. Push wifi kernel module to your device:
```shell
adb shell mv /system/lib/modules/pronto/pronto_wlan.ko /system/lib/modules/pronto/pronto_wlan.ko.bak  # IMPORTANT! Backup your current wifi module because if you flash back stock kernel, wifi will not work!
adb push out/drivers/staging/prima/wlan.ko /system/lib/modules/pronto/pronto_wlan.ko
adb shell chmod 0644 /system/lib/modules/pronto/pronto_wlan.ko
```
14. Reboot your device to fastboot
15. Boot image you just repacked:
```shell
fastboot boot new_boot.img
```
16. If your device is working properly and new boot image is stable, flash new boot image:
```shell
fastboot flash boot new_boot.img
```
17. To revert wifi kernel module to the stock one (use only with stock boot image):
```shell
adb shell rm /system/lib/modules/pronto/pronto_wlan.ko
adb shell mv /system/lib/modules/pronto/pronto_wlan.ko.bak /system/lib/modules/pronto/pronto_wlan.ko
adb reboot
```
