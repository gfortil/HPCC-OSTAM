#!/bin/bash 

# ---
# Create log for provisioning script and output stdout and stderr to it
# ---
LOG=/var/log/provisioner.log
exec > $LOG 2>&1
set -x

# Set timezone
export TZ="/usr/share/zoneinfo/America/${timezone}"
echo "export TZ=\"/usr/share/zoneinfo/America/${timezone}\"" >> ~/.bashrc
$(cat ~/.bashrc | grep TZ)

# ---
# Format and mount filesystems
# ---

# mount | grep ${device}
# if [ $? -eq 0 ]
# then
#     echo "${device} was already mounted"
# else

if [ "$(df -Th | grep ${device} | awk '{print $1}')" == "${device}" ]
then
    echo "${device} has already been mounted."
else
    echo "Format ${device}"

    # This block is necessary to prevent provisioner from continuing before volume is attached
    while [ ! -b ${device} ]; do sleep 1; done

    UUID=$(lsblk -no UUID ${device})

    if [ -z $UUID ]
    then
        mkfs.ext4 ${device}
    fi
    
    if [ ! -d ${mountpoint} ]
    then
        mkdir -p ${mountpoint}
    fi
    
    sleep 5

    grep ${mountpoint} /etc/fstab
    if [ $? -ne 0 ]
    then
        echo "Add ${device} to /etc/fstab"
        echo "UUID=$UUID ${mountpoint}    xfs    noatime    0 0" >> /etc/fstab
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

move_dir () {
    if [ -d ${mountpoint}$1 ] # if directory exist on the mounted volume
    then
        if [ -d $1 ]
        then
            rm $1 -rf
        fi

        ln -s ${mountpoint}$1 $1
    else    
        mkdir -p ${mountpoint}$1
        chown hpcc:hpcc ${mountpoint}$1 -R
        if [ -d $1 ] # if directory exists on root volume
        then
            cp -avr $1/* ${mountpoint}/$1
            rm -r $1 
        fi

        ln -s ${mountpoint}$1 $1
        chown hpcc:hpcc $1 -R
    fi
}


if [ `hostname -s` == "${project_name}-esp_*" ]
then
    move_dir /downloads
fi

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
	elif [ `cat /etc/os-release | grep VERSION_ID` == 'VERSION_ID="7"' ]; then
		distro="el7"
   	fi
fi

# Remove package if it exists
if [ -e /tmp/hpccsystems-platform-* ]
then
    rm /tmp/hpccsystems-platform-* -rf
fi

if [ $isDebian == false ]
then
    # ---
    # Install dependencies
    # ---

    # Enable EPEL
    #yum --enablerepo=LN-epel
    sed -i '/LN-epel/,/enabled=0/ s/enabled=0/enabled=1/' /etc/yum.repos.d/LexisNexis.repo
    sed -i '/LN-base/,/enabled=0/ s/enabled=0/enabled=1/' /etc/yum.repos.d/LexisNexis.repo
    sed -i '/LN-updates/,/enabled=0/ s/enabled=0/enabled=1/' /etc/yum.repos.d/LexisNexis.repo

    # Copy RPM-GPG-KEY for EPEL-7 into /etc/pki/rpm-gpg
    cp /home/centos/RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg
    cp /home/centos/RPM-GPG-KEY-remi /etc/pki/rpm-gpg

    yum update -y

    if [ ${edition} == "CE" ]
    then
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm -P /tmp -a /var/log/wget.log
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm ] && [ -e /tmp/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-community_${version}-${release}.$distro.x86_64.rpm.md5 | awk '{print $1}')
        else
            echo ".rpm or .rpm.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    elif [ ${edition} == "LN" ]
    then
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm -P /tmp -a /var/log/wget.log
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm ] && [ -e /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}.$distro.x86_64.rpm.md5 | awk '{print $1}')
        else
            echo ".rpm or .rpm.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    else
        echo "Wrong package type: ${edition}"
        echo "Available package types: CE, LN"
        exit 1
    fi

    if [ $A == $B ]
    then
        yum install git -y
        yum install -y /tmp/hpccsystems-platform-*.rpm
        sed -i '0,/session/ s//session         [success=ignore default=1] pam_succeed_if.so user = hpcc\nsession         sufficient      pam_unix.so\nsession/' /etc/pam.d/su
    fi

    yum install -y httpd-tools

elif [ $isDebian == true ]
then
    if [ ${edition} == "CE" ]
    then
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb -P /tmp -a /var/log/wget.log
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb.md5 -P /tmp -a /var/log/wget.log

        if [ -e /tmp/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb ] && [ -e /tmp/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-community_${version}-${release}$distro_amd64.deb.md5 | awk '{print $1}')
        else
            echo ".deb or .deb.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    elif [ ${edition} == "LN" ]
    then
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb -P /tmp -a /var/log/wget.log
        wget http://${server}/builds/${edition}-Candidate-${version}/bin/platform-withplugins-spark/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb.md5 -P /tmp -a /var/log/wget.log
    
        if [ -e /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb ] && [ -e /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb.md5 ]
        then
            #checksum
            A=$(md5sum /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb | awk '{print $1}')
            B=$(cat /tmp/hpccsystems-platform-internal-with-spark_${version}-${release}$distro_amd64.deb.md5 | awk '{print $1}')
        else
            echo ".deb or .deb.md5 file is missing"
            echo "Exiting now"
            exit 1
        fi
    else
        echo "Wrong edition: ${edition}"
        echo "Available editions: CE, LN"
        exit 1
    fi

    if [ $A == $B ]
    then
        apt-get install git -y
        dpkg -i /tmp/hpccsystems-platform-*.deb
        apt-get install -f -y
        sed -i '0,/session/ s//session         [success=ignore default=1] pam_succeed_if.so user = hpcc\nsession         sufficient      pam_unix.so\nsession/' /etc/pam.d/su
    fi

    apt-get update
    apt-get install apache2 apache2-utils

else
    echo "Unsupported distro: $distro"
    echo "Currently support distros: el7, el6, disco, bionic, xenial."
    exit 1
fi

ecl --version #verify build

move_dir /var/log/HPCCSystems
move_dir /var/lib/HPCCSystems

if [ `hostname -s` == "${project_name}-dropzone" ]
then
    for folder in ${mydropzone_folder_names}
    do
        if [ ! -d ${mountpoint}/var/lib/HPCCSystems/mydropzone/$folder ]
        then
            mkdir -m 775 -p -v ${mountpoint}/var/lib/HPCCSystems/mydropzone/$folder
        else
            echo "A folder named $folder already exist"
        fi
    done
fi


if [ `hostname -s` == "${project_name}-esp_"* ] && [ -e ${mountpoint}/etc/HPCCSystems/.htpasswd ]
then        
    #     htpasswd -c -b -B /etc/HPCCSystems/.htpasswd admin
    ln -s ${mountpoint}/etc/HPCCSystems/.htpasswd /etc/HPCCSystems/.htpasswd
fi

if [ -e ${mountpoint}/etc/HPCCSystems/environment.xml ]
then
    if [ -e /etc/HPCCSystems/environment.xml ]
    then
        rm -rf /etc/HPCCSystems/environment.xml
    fi
    ln -s ${mountpoint}/etc/HPCCSystems/environment.xml /etc/HPCCSystems/environment.xml
    chown hpcc:hpcc /etc/HPCCSystems/environment.xml
    /etc/init.d/hpcc-init start
fi
echo "Done provisioning!"
exit 0

