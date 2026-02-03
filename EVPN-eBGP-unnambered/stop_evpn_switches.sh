#!/bin/bash

docker stop host host3 host4 leaf1 leaf2 leaf3 leaf4 spine1 spine2 supspine
docker rm host host3 host4 leaf1 leaf2 leaf3 leaf4 spine1 spine2 supspine

for i in host3 host4 leaf1 leaf2 leaf3 leaf4 spine1 spine2 supspine; do
	ip netns del ${i}
done
