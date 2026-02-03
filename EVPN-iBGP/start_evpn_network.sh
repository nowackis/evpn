#!/bin/bash

set -x

#TODO following two commands probably needs a good $CONFIG_PATH to make this a bit usable (not hardcoded absolute-path)

CONFIG_PATH="$(dirname "$(realpath "$0")")"

# Start testing host container
docker run --name host \
  --hostname host \
  --net=host \
  --privileged \
  -d \
  --restart=always \
  -it \
  -v ${CONFIG_PATH}/host.conf:/etc/frr/frr.conf \
  -v ${CONFIG_PATH}/daemons:/etc/frr/daemons \
  -v ${CONFIG_PATH}/vtysh.conf:/etc/frr/vtysh.conf \
  quay.io/frrouting/frr:10.1.3

# Start virtual switches
for i in leaf1 leaf2 leaf3 leaf4 spine1 spine2 supspine host3 host4; do
  docker run --name ${i} \
    --hostname ${i} \
    --net=none \
    --privileged \
    -d \
    --restart=always \
    -it \
    -v ${CONFIG_PATH}/${i}.conf:/etc/frr/frr.conf \
    -v ${CONFIG_PATH}/daemons:/etc/frr/daemons \
    -v ${CONFIG_PATH}/vtysh.conf:/etc/frr/vtysh.conf \
    quay.io/frrouting/frr:10.1.3
done

echo "waiting for containers to start"
sleep 10

#ensure namespace dir exists
mkdir -p /var/run/netns

#TODO generally add 1 more pod (2 leafs, 1 spine) so that we can move the host into a "test-host" namespace as ovn-bgp-agent will take its current space
#remove symlinks if they exist
rm -f /var/run/netns/leaf*
rm -f /var/run/netns/spine*
rm -f /var/run/netns/supspine*
rm -f /var/run/netns/host3
rm -f /var/run/netns/host4

#get pids of the evpn containers
pid_leaf1=$(docker inspect -f '{{.State.Pid}}' leaf1)
pid_leaf2=$(docker inspect -f '{{.State.Pid}}' leaf2)
pid_leaf3=$(docker inspect -f '{{.State.Pid}}' leaf3)
pid_leaf4=$(docker inspect -f '{{.State.Pid}}' leaf4)
pid_spine1=$(docker inspect -f '{{.State.Pid}}' spine1)
pid_spine2=$(docker inspect -f '{{.State.Pid}}' spine2)
pid_supspine=$(docker inspect -f '{{.State.Pid}}' supspine)
pid_host3=$(docker inspect -f '{{.State.Pid}}' host3)
pid_host4=$(docker inspect -f '{{.State.Pid}}' host4)
#are containers running?
if [ "$pid_leaf1" -le 1 ] || [ "$pid_leaf2" -le 1 ] || [ "$pid_leaf3" -le 1 ] || [ "$pid_leaf4" -le 1 ] || [ "$pid_spine1" -le 1 ] || [ "$pid_spine2" -le 1 ] || [ "$pid_supspine" -le 1 ] || [ "$pid_host31" -le 1 ] || [ "$pid_host41" -le 1 ]; then
  echo "start all evpn leafs/spines/superspines"
  exit 1
fi

#create symlinks for dockers (creating the namespaces) ip netns add not required..
ln -s /proc/$pid_leaf1/ns/net /var/run/netns/leaf1
ln -s /proc/$pid_leaf2/ns/net /var/run/netns/leaf2
ln -s /proc/$pid_leaf3/ns/net /var/run/netns/leaf3
ln -s /proc/$pid_leaf4/ns/net /var/run/netns/leaf4
ln -s /proc/$pid_spine1/ns/net /var/run/netns/spine1
ln -s /proc/$pid_spine2/ns/net /var/run/netns/spine2
ln -s /proc/$pid_supspine/ns/net /var/run/netns/supspine
ln -s /proc/$pid_host3/ns/net /var/run/netns/host3
ln -s /proc/$pid_host4/ns/net /var/run/netns/host4

#     pod #0
#
#       superspine
#       /        \
#    spine1    spine2
#     /  \       /  \
#  leaf1 leaf2 leaf3 leaf4
#    |     |     |     |
#  nic1   nic2 host3  host4

#create ALL the veth pairs 
ip link add nic1 type veth peer name leaf1-nic1
ip link add nic2 type veth peer name leaf2-nic2
ip link add host3-leaf3 type veth peer name leaf3-host3
ip link add host4-leaf4 type veth peer name leaf4-host4
ip link add leaf1-spine1 type veth peer name spine1-leaf1
ip link add leaf2-spine1 type veth peer name spine1-leaf2
ip link add leaf3-spine2 type veth peer name spine2-leaf3
ip link add leaf4-spine2 type veth peer name spine2-leaf4
ip link add spine1-supspine type veth peer name supspine-spine1
ip link add spine2-supspine type veth peer name supspine-spine2

#move the links to correct namespaces
ip link set leaf1-nic1 netns leaf1
ip link set leaf2-nic2 netns leaf2
ip link set host3-leaf3 netns host3
ip link set host4-leaf4 netns host4
ip link set leaf3-host3 netns leaf3
ip link set leaf4-host4 netns leaf4
ip link set leaf1-spine1 netns leaf1
ip link set leaf2-spine1 netns leaf2
ip link set leaf3-spine2 netns leaf3
ip link set leaf4-spine2 netns leaf4
ip link set spine1-leaf1 netns spine1
ip link set spine1-leaf2 netns spine1
ip link set spine2-leaf3 netns spine2
ip link set spine2-leaf4 netns spine2
ip link set spine1-supspine netns spine1
ip link set spine2-supspine netns spine2
ip link set supspine-spine1 netns supspine
ip link set supspine-spine2 netns supspine

#all interfaces up
ip link set nic1 up
ip link set nic2 up
ip netns exec host3 ip link set host3-leaf3 up
ip netns exec host4 ip link set host4-leaf4 up
ip netns exec leaf1 ip link set leaf1-nic1 up
ip netns exec leaf1 ip link set leaf1-spine1 up
ip netns exec leaf2 ip link set leaf2-nic2 up
ip netns exec leaf2 ip link set leaf2-spine1 up
ip netns exec leaf3 ip link set leaf3-host3 up
ip netns exec leaf3 ip link set leaf3-spine2 up
ip netns exec leaf4 ip link set leaf4-host4 up
ip netns exec leaf4 ip link set leaf4-spine2 up
ip netns exec spine1 ip link set spine1-leaf1 up
ip netns exec spine1 ip link set spine1-leaf2 up
ip netns exec spine1 ip link set spine1-supspine up
ip netns exec spine2 ip link set spine2-leaf3 up
ip netns exec spine2 ip link set spine2-leaf4 up
ip netns exec spine2 ip link set spine2-supspine up
ip netns exec supspine ip link set supspine-spine1 up
ip netns exec supspine ip link set supspine-spine2 up

#assign ips to evpn fabric
ip addr add 10.0.1.1/31 dev nic1
ip netns exec leaf1 ip addr add 10.0.1.0/31 dev leaf1-nic1

ip addr add 10.0.1.3/31 dev nic2
ip netns exec leaf2 ip addr add 10.0.1.2/31 dev leaf2-nic2

ip netns exec host3 ip addr add 10.0.1.5/31 dev host3-leaf3
ip netns exec leaf3 ip addr add 10.0.1.4/31 dev leaf3-host3

ip netns exec host4 ip addr add 10.0.1.7/31 dev host4-leaf4
ip netns exec leaf4 ip addr add 10.0.1.6/31 dev leaf4-host4

ip netns exec leaf1 ip addr add 10.0.2.0/31 dev leaf1-spine1
ip netns exec spine1 ip addr add 10.0.2.1/31 dev spine1-leaf1

ip netns exec leaf2 ip addr add 10.0.2.2/31 dev leaf2-spine1
ip netns exec spine1 ip addr add 10.0.2.3/31 dev spine1-leaf2

ip netns exec leaf3 ip addr add 10.0.2.4/31 dev leaf3-spine2
ip netns exec spine2 ip addr add 10.0.2.5/31 dev spine2-leaf3

ip netns exec leaf4 ip addr add 10.0.2.6/31 dev leaf4-spine2
ip netns exec spine2 ip addr add 10.0.2.7/31 dev spine2-leaf4

ip netns exec spine1 ip addr add 10.0.3.1/31 dev spine1-supspine
ip netns exec supspine ip addr add 10.0.3.0/31 dev supspine-spine1

ip netns exec spine2 ip addr add 10.0.3.3/31 dev spine2-supspine
ip netns exec supspine ip addr add 10.0.3.2/31 dev supspine-spine2
