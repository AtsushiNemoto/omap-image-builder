#!/bin/bash

export apt_proxy=192.168.1.12:3142/

config=bb.org-debian-bookworm-xfce-mainline-rt-arm64
filesize=10gb
rootfs="debian-arm64-12-bookworm-xfce-mainline-rt"

compress_snapshot_image () {
	json_file="${device}-${export_filename}-${filesize}.img.xz.json"
	sudo -uvoodoo mkdir -p /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sync
	echo "        {" >> ${json_file}
	echo "            \"name\": \"Debian 12 ${image_type} (${deb_arch})\"," >> ${json_file}
	echo "            \"description\": \"A port of Debian Bookworm with the ${image_type} package set\"," >> ${json_file}
	echo "            \"icon\": \"https://rcn-ee.net/rootfs/release/BorisImageWriter.png\"," >> ${json_file}
	echo "            \"url\": \"https://rcn-ee.net/rootfs/${rootfs}/${time}/${device}-${export_filename}-${filesize}.img.xz\"," >> ${json_file}
	extract_size=$(du -b ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "            \"extract_size\": ${extract_size}," >> ${json_file}
	extract_sha256=$(sha256sum ./${device}-${export_filename}-${filesize}.img | awk '{print $1}')
	echo "            \"extract_sha256\": \"${extract_sha256}\"," >> ${json_file}

	echo "Compressing...${device}-${export_filename}-${filesize}.img"
	xz -T4 -z ${device}-${export_filename}-${filesize}.img
	sync

	image_download_size=$(du -b ./${device}-${export_filename}-${filesize}.img.xz | awk '{print $1}')
	echo "            \"image_download_size\": ${image_download_size}," >> ${json_file}
	echo "            \"release_date\": \"${time}\"," >> ${json_file}
	echo "            \"init_format\": \"systemd\"" >> ${json_file}
	echo "        }," >> ${json_file}
	sync

	sha256sum ${device}-${export_filename}-${filesize}.img.xz > ${device}-${export_filename}-${filesize}.img.xz.sha256sum
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	sudo -uvoodoo cp -v ./${device}-${export_filename}-${filesize}.img.xz.json /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
}

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

touch .notar
touch .gitea.mirror
echo "./RootStock-NG.sh -c ${config}"
./RootStock-NG.sh -c ${config}

source .project

if [ -d ./deploy/${export_filename}/ ] ; then
	cd ./deploy/${export_filename}/

	echo "sudo ./setup_sdcard.sh --img-${filesize} bbai64-${export_filename} --dtb bbai64 --hostname BeagleBone-AI64"
	sudo ./setup_sdcard.sh --img-${filesize} bbai64-${export_filename} --dtb bbai64 --hostname BeagleBone-AI64
	mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} bbai64-ti-2023.04-${export_filename} --dtb bbai64-ti-2023.04 --hostname BeagleBone-AI64"
	sudo ./setup_sdcard.sh --img-${filesize} bbai64-ti-2023.04-${export_filename} --dtb bbai64-ti-2023.04 --hostname BeagleBone-AI64
	#mv ./*.img ../

	echo "sudo ./setup_sdcard.sh --img-${filesize} beagleplay-${export_filename} --dtb beagleplay-swap --hostname BeaglePlay"
	sudo ./setup_sdcard.sh --img-${filesize} beagleplay-${export_filename} --dtb beagleplay-swap --hostname BeaglePlay
	mv ./*.img ../

	#echo "sudo ./setup_sdcard.sh --img-${filesize} beagleplay-ti-2023.04-${export_filename} --dtb beagleplay-swap-ti-2023.04 --hostname BeaglePlay"
	#sudo ./setup_sdcard.sh --img-${filesize} beagleplay-ti-2023.04-${export_filename} --dtb beagleplay-swap-ti-2023.04 --hostname BeaglePlay
	#mv ./*.img ../

	#echo "sudo ./setup_sdcard.sh --img-${filesize} beagleplay-mainline-${export_filename} --dtb beagleplay-mainline --hostname BeaglePlay"
	#sudo ./setup_sdcard.sh --img-${filesize} beagleplay-mainline-${export_filename} --dtb beagleplay-mainline --hostname BeaglePlay
	#mv ./*.img ../

	cd ../

	device="bbai64" ; compress_snapshot_image
	device="bbai64-ti-2023.04" ; compress_snapshot_image
	device="beagleplay" ; compress_snapshot_image
	#device="beagleplay-ti-2023.04" ; compress_snapshot_image
	#device="beagleplay-mainline" ; compress_snapshot_image

	#echo "Compressing...${export_filename}.tar"
	#xz -T4 -z ${export_filename}.tar
	#sha256sum ${export_filename}.tar.xz > ${export_filename}.tar.xz.sha256sum
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/
	#sudo -uvoodoo cp -v ./${export_filename}.tar.xz.sha256sum /mnt/mirror/rcn-ee.us/rootfs/${rootfs}/${time}/

	rm -rf ${tempdir} || true
else
	echo "failure"
	exit 2
fi
#
