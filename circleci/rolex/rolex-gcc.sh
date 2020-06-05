#! /usr/bin/env bash
echo "Export VAR"
export TOKEN=$token
export CID=$chat_id
export TIME=$(date +"%S-%F")
export BRANCH=$(git rev-parse --abbrev-ref HEAD)
export ZIPNAME=WyrdKernel-${TIME}
echo "Done..."
echo "Cloning dependencies"
git clone https://github.com/mfiqrizalvi/Flashable-Kernol.git --depth 1
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b ndk-r21c gcc
echo "Done..."
GCC="$(pwd)/gcc/bin/aarch64-linux-android-"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DATE=`date`
BUILD_START=$(date +"%s")
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=mfiqrizalvi
export KBUILD_BUILD_HOST=Sluccy
export CROSS_COMPILE="${GCC}"
# Push Kernel to channel
function push() {
	cd Flashable-Kernol  || exit 1
    ZIP=$(echo *.zip)
	curl -F document=@$ZIPNAME.zip "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id=$CID\
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html"
}
# Send info
function sendinfo() {
	curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id=$CID \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>WyrdKernel</b> new build is up!%0A$(TZ=Asia/Jakarta date)%0AFor <b>Xiaomi Redmi 4A/5A</b>%0AAt branch <strong>$BRANCH</strong>%0ACompiler <b>$COMPILER</b>%0AUnder commit <code>$(git log --pretty=format:'"%s"' -1)</code>%0A<b>$(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)</b>"
}
# sticker plox
function sticker() {
	curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
 	    -d sticker="CAACAgUAAxkBAAJZp16ppVRW9CHlgDYxg2vbUcljqnLuAAIJAAM4BDYw9rV-Rh-_si0ZBA" \
 	    -d chat_id=$CID
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id=$CID\
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Job build throw an error(s)"  
    exit 1
}

echo "Start Building..."
make mrproper
mkdir -p out
make O=out rolex_defconfig
make O=out -j$(nproc --all) -l$(nproc --all) 
if ! [ -a ${IMAGE} ]; then
finerr
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb Flashable-Kernol
cd Flashable-Kernol
mv Image.gz-dtb zImage
zip -r9 ${ZIPNAME}.zip * -x build.sh
cd .. #well
echo "Well Done..."
sticker
BUILD_END=$(date +"%s")
DIFF=$((${BUILD_END} - ${BUILD_START}))
COMPILER=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
sendinfo
push
