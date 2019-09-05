#!/bin/bash 

# ---
# Create log for provisioning script and output stdout and stderr to it
# ---
LOG=/var/log/provisioner.log
exec > $LOG 2>&1
set -x

# ---
# Format and mount filesystems
# ---

mount | grep ${device}
if [ $? -eq 0 ]
then
    echo "${device} was already mounted"
else
    echo "Format ${device}"

    # This block is necessary to prevent provisioner from contiuing before volume is attached
    while [ ! -b ${device} ]; do sleep 1; done

    mkfs.ext4 ${device}
    mkdir -p ${mountpoint}
    
    sleep 5

    grep ${mountpoint} /etc/fstab
    if [ $? -ne 0 ]
    then
        echo "Add ${device} to /etc/fstab"
        FS_UUID=$(lsblk -no UUID ${device})
        echo "UUID=$FS_UUID ${mountpoint}    xfs    noatime    0 0" >> /etc/fstab
    fi

    echo "Mount ${device}"
    mount ${device} ${mountpoint}
fi

df -h

# ---
# Add hostname to /etc/hosts
# ---

grep `hostname` /etc/hosts
if [ $? -ne 0 ]
then
    echo "Add hostname and ip to /etc/hosts"
    echo "${ip} `hostname -s` `hostname`" >> /etc/hosts
fi

# ---
# Move directories from bootdisk to mountpoint
# ---
move_dir () {
    if [ ! -d ${mountpoint}$1 ] # if directory doesn't exist on the mounted volume
    then
        mkdir -p ${mountpoint}$1
        if [ -d $1 ] # if directory exists on root volume
        then
            mv $1 ${mountpoint}$(dirname "$1")
        fi
        ln -s ${mountpoint}$1 $1
    fi
}

move_dir /usr/local
move_dir /opt
move_dir /tmp

if [ $(hostname -s) == "lzone" ]
then
    for folder in ${mydropzone_folder_names}
    do
        mkdir /var/lib/HPCCSystems/$folder
        move_dir /var/lib/HPCCSystems/$folder
    done
fi

# Set timezone
export TZ="/usr/share/zoneinfo/America/${timezone}"
echo "export TZ="/usr/share/zoneinfo/America/${timezone}"" | sudo tee -a ~/.bashrc

# ---
# Install HPCC
# ---

# Determines distro

distro=""
isDebian=false
A=""
B=""

if [ -e /etc/lsb-release ]; then
	distro=$(cat /etc/os-release | grep UBUNTU_CODENAME | cut -b 17-)
    isDebian=true
elif [ -e /etc/redhat-release ]; then
	if [ ! -f /etc/os-release ]; then
    	distro="el6"
	elif [ $(cat /etc/os-release | grep VERSION_ID) == 'VERSION_ID="7"' ]; then
		distro="el7"
   	fi
fi

# Remove package if it exists
if [ -e /tmp/hpccsystems-platform-* ]
then
    rm /tmp/hpccsystems-platform-* -rf
fi

if [ $isDebian == false -a 'hostname -s' != "lzone" ]
then
    # ---
    # Install dependencies
    # ---

    # Enable EPEL
    #yum --enablerepo=LN-epel
    sed -i '/LN-epel/,/enabled=0/ s/enabled=0/enabled=1/' /etc/yum.repos.d/LexisNexis.repo

    # Copy RPM-GPG-KEY for EPEL-7 into /etc/pki/rpm-gpg
    cp /etc/pki/rpm-gpg/files/RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg

    yum update -y

    if [ ${hpcc_package} == "CE" ]
    then
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm -P /tmp -a /var/log/wget.log
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm ] && [ -e /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 | awk '{print $1}')
        else
            echo ".rpm or .rpm.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    elif [ ${hpcc_package} == "LN" ]
    then
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm -P /tmp -a /var/log/wget.log
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm ] && [ -e /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}.$distro.x86_64.rpm.md5 | awk '{print $1}')
        else
            echo ".rpm or .rpm.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    else
        echo "Wrong package type: ${hpcc_package}"
        echo "Available package types: CE, LN"
        exit 1
    fi

    if [ $A == $B ]
    then
        yum install -y /tmp/hpccsystems-platform-*.rpm
    fi
elif [ $isDebian == true -a 'hostname -s' != "lzone" ]
then
    if [ ${hpcc_package} == "CE" ]
    then
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb -P /tmp -a /var/log/wget.log
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb ] && [ -e /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-community_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 | awk '{print $1}')
        else
            echo ".deb or .deb.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    elif [ ${hpcc_package} == "LN" ]
    then
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb -P /tmp -a /var/log/wget.log
        wget http://${build_server}/builds/${hpcc_package}-Candidate-${hpcc_version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 -P /tmp -a /var/log/wget.log
    
        if [ -e /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb ] && [ -e /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-internal-with-spark_${hpcc_version}-${hpcc_release}$distro_amd64.deb.md5 | awk '{print $1}')
        else
            echo ".deb or .deb.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    else
        echo "Wrong package type: ${hpcc_package}"
        echo "Available package types: CE, LN"
        exit 1
    fi

    if [ $A == $B ]
    then
        dpkg -i /tmp/hpccsystems-platform-*.deb
        apt-get install -f -y
    fi

else
    echo "Unsupported distro: $distro"
    echo "Currently support distros: el7, el6, disco, bionic, xenial."
    exit 1
fi

echo "Done provisioning!"
exit 0
