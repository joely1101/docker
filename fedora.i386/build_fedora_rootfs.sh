fc_version=18 
fc_arch=i386
download_dir=$PWD/download
dest_rootfs_dir=$PWD/dest_rootfs
curent_path=$PWD
uid=`id -u`

if [ "$uid" != "0" ]; then
   echo "You must be root to do this." 1>&2
   exit 100
fi
[ ! -d $download_dir ] && mkdir -p $download_dir
[ ! -d $dest_rootfs_dir ] && mkdir -p $dest_rootfs_dir

error_out()
{
    echo "Error:"
    echo $@
    umount $curent_path/stage0 &>/dev/null
    umount $curent_path/squashfs &>/dev/null
    umount $dest_rootfs_dir/dev &>/dev/null
    umount $dest_rootfs_dir/proc &>/dev/null
    exit 99
    
}
download_requirs_files()
{
    cd $download_dir
    
    if [ ! -f squashfs.img ];then
        wget -N http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/LiveOS/squashfs.img
        
        if [ "$?" != "0" ];then
           error_out "download squashfs.img fail!!" 
        fi
    fi
    wget -q http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/r/ -O - | \
    grep -o  "a href=\"rpm-.*.rpm\"" |  grep -o  "rpm-.*.rpm" | \
    xargs -i wget -N http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/r/{}
    
    if [ "$?" != "0" ];then
       error_out "download rpm-.*.rpm fail!!" 
    fi


    wget -q http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/y/ -O - | \
    grep -o  "a href=\"yum-.*.rpm\"" |  grep -o  "yum-.*.rpm" | \
    xargs -i wget -N http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/y/{}
    
    
    if [ "$?" != "0" ];then
       error_out "download yum-.*.rpm fail!!" 
    fi
    
    wget -q http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/f/ -O - | \
    grep -o  "a href=\"fedora-release-${fc_version}.*.rpm\"" |  grep -o  "fedora-release-.*.rpm" | \
    xargs -i wget -N http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/f/{}
    
    if [ "$?" != "0" ];then
       error_out "download fedora-release-.*.rpm fail!!" 
    fi
    
    wget -q http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/u/ -O - | \
    grep -o  "a href=\"util-linux-.*.rpm\"" |  grep -o  "util-linux-.*.rpm" | \
    xargs -i wget -N http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$fc_version/Fedora/$fc_arch/os/Packages/u/{}
    
    if [ "$?" != "0" ];then
       error_out "download util-linux-.*.rpm fail!!" 
    fi
    cd -
}

base_rootfs()
{
    mkdir -p squashfs stage0 $dest_rootfs_dir
    echo "mount -o loop $download_dir/squashfs.img squashfs"
    mount -o loop $download_dir/squashfs.img squashfs
    if [ "$?" != "0" ];then
        error_out "Mount of LiveOS squashfs image failed!  You mush have squashfs support
            available to mount image.  Unable to continue.  If squashfs.img is corrupt,
            remove squashfs.img before rerunning to redownload."
    fi
    
    mount -o loop squashfs/LiveOS/rootfs.img stage0
    if [ "$?" != "0" ];then
        error_out "Mount of squashfs/LiveOS/rootfs.img failed"
    fi
    echo "Stage 0 complete, building Stage 1 image...
          This will take a couple of minutes.  Patience..."

    echo "Creating Stage 1 r/w copy of r/o Stage 0 squashfs image from LiveOS."

    rsync -aAHS stage0/. $dest_rootfs_dir/
    umount stage0 squashfs
    rm -rf stage0 squashfs

}
base_rpm_install()
{
    mkdir -p $dest_rootfs_dir/rpm
    mount -o bind $download_dir $dest_rootfs_dir/rpm
    chroot $dest_rootfs_dir rpm -ivh --nodeps /rpm/rpm-* /rpm/yum-* 
    echo "install fedora-release"
    chroot $dest_rootfs_dir rpm -ivh --nodeps /rpm/fedora-release*
    echo "install util-linux"
    chroot $dest_rootfs_dir rpm -ivh --nodeps /rpm/util-linux*
    
    umount $dest_rootfs_dir/rpm
    rm -rf $dest_rootfs_dir/rpm

}

configure_yum()
{
    dolinux32=
    if [ "$fc_arch" = "i386" -o "$fc_arch" = "i586" -o "$fc_arch" = "i686" ];then
        dolinux32=linux32
    fi
    
    sed -i "s|mirrorlist=https|mirrorlist=http|"  $dest_rootfs_dir/etc/yum.repos.d/*
    echo "nameserver 8.8.8.8" > $dest_rootfs_dir/etc/resolv.conf
    echo "reinstall ca-certificates and dolinux32=$dolinux32"
    chroot $dest_rootfs_dir $dolinux32 yum update ca-certificates yum rpm python
    chroot $dest_rootfs_dir $dolinux32 yum install -y yum
    chroot $dest_rootfs_dir $dolinux32 yum install -y rpm
    chroot $dest_rootfs_dir $dolinux32 yum install -y python
    chroot $dest_rootfs_dir $dolinux32 yum install -y ca-certificates
    #sed -i "s|mirrorlist=http|mirrorlist=https|"  $dest_rootfs_dir/etc/yum.repos.d/*
    chroot $dest_rootfs_dir $dolinux32 yum update -y
}


download_requirs_files
base_rootfs

mount -o bind /proc/ $dest_rootfs_dir/proc
mount -o bind /dev/ $dest_rootfs_dir/dev

base_rpm_install
configure_yum

umount $dest_rootfs_dir/proc $dest_rootfs_dir/dev
