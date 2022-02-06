#!/bin/bash

VENDOR=univention
IMAGE=ucs-generic-amd64
VERSION=4.4-4
CONTAINER_NAME=dockertest
PASSWORD=geheim
NAMESERVER=8.8.8.8

TEMPDIR=$(mktemp -d)

#docker run -d -it --name ${CONTAINER_NAME} \
#    --hostname=${CONTAINER_NAME} \
#    -e domainname=testdomain.intranet \
#    -e rootpwd=${PASSWORD} \
#    -p 8015:80 \
#    -e nameserver1=${NAMESERVER} \
#    -e container=docker \
#    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#    --tmpfs /run --tmpfs /run/lock \
#    --cap-add=SYS_ADMIN \
#    --restart unless-stopped \
#    ${VENDOR}/${IMAGE}:${VERSION} /sbin/init
#docker exec -it ${CONTAINER_NAME} univention-upgrade --noninteractive
#docker exec -it ${CONTAINER_NAME} apt-get install --no-install-recommends univention-system-setup-boot
#docker exec -it ${CONTAINER_NAME} univention-system-setup-boot start
#docker stop ${CONTAINER_NAME}
docker create --name ${CONTAINER_NAME} ${VENDOR}/${IMAGE}:${VERSION}
docker export -o ${TEMPDIR}/image.tar ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}
mkdir "${TEMPDIR}/rootfs"
tar xf "${TEMPDIR}/image.tar" -C "${TEMPDIR}/rootfs"
cat <<EOF >${TEMPDIR}/rootfs/config
xc.network.type = veth
lxc.network.hwaddr = 00:16:3e:27:42:b0
lxc.network.link = br0
lxc.network.flags = up

configuration - br1 - external
#lxc.network.type = veth
#lxc.network.hwaddr = 00:16:3e:27:42:b1
#lxc.network.link = br1
#lxc.network.flags = up

lxc.rootfs = /var/lib/lxc/mab42/rootfs

Common configuration
lxc.include = /usr/share/lxc/config/debian.common.conf
lxc.include = /usr/share/lxc/config/debian.jessie.conf

Container specific configuration
lxc.tty = 4
lxc.utsname = ucs{$VERSION}
lxc.arch = amd64
lxc.start.auto = 0
lxc.environment = domainname=privat.domain
lxc.environment = hostname=ucs{$VERSION}
lxc.environment = interfaces/eth0/address=192.168.33.22
lxc.environment = interfaces/eth0/broadcast=192.168.33.255
lxc.environment = interfaces/eth0/netmask=255.255.255.0
lxc.environment = interfaces/eth0/type=static
lxc.environment = interfaces/primary=eth0
lxc.environment = gateway=192.168.33.1
lxc.environment = dns/forwarder1=${NAMESERVER}
lxc.environment = nameserver1=${NAMESERVER}
lxc.environment = rootpwd=univention
lxc.environment = appcenter/docker=false
EOF
echo "tar cfz ${IMAGE}-${VERSION}.tar -C ${TEMPDIR}/rootfs ."
tar cfz "${IMAGE}-${VERSION}.tar" -C "${TEMPDIR}/rootfs" .
#rm -rf ${TEMPDIR}
