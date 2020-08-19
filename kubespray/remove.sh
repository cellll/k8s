#!/bin/bash

ansible-playbook -i inventory/test/hosts.yaml remove-node.yml -b -v --extra-vars "node=xiilab-gpunode2"