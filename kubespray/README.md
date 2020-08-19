### Kubernetes : Kubespray + nvidia-device-plugin
---

#### 1. Kubespray

**Docker 설치, Nvidia-docker 설치, default-runtime 설정 자동화**


##### 클러스터 배포 

```ShellSession
# Install dependencies from ``requirements.txt``
sudo pip3 install -r requirements.txt

# Copy ``inventory/sample`` as ``inventory/mycluster``
cp -rfp inventory/sample inventory/mycluster

# Update Ansible inventory file with inventory builder
declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# Hostname 변경 방지 
> inventory/mycluster/hosts.yaml
  node1, node2, ... -> <HOST_NAME> 으로 변경 


# Review and change parameters under ``inventory/mycluster/group_vars``
cat inventory/mycluster/group_vars/all/all.yml
cat inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml

# Deploy Kubespray with Ansible Playbook - run the playbook as root
# The option `--become` is required, as for example writing SSL keys in /etc/,
# installing packages and interacting with various systemd daemons.
# Without --become the playbook will fail to run!

ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml
```


##### 클러스터 삭제 

```
ansible-playbook -i inventory/mycluster/hosts.yaml remove-node.yml -b -v --extra-vars "node=<NODE_NAME>"
```



##### Docker 설정 변경

```
1. Docker 버전 변경 

> roles/container-engine/docker/defaults/main.yml
	docker_version: '18.09'
	docker_cli_version: "{{ 'latest' if docker_version != 'latest' and docker_version is version('18.09', '<') else docker_version }}"
	docker_selinux_version: '17.03'

2. Docker Option 변경
 
> inventory/mycluster/group_vars/all/docker.yml
 	docker_options: " -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"

3. Docker DNS 변경

> inventory/test/group_vars/all/docker.yml
	docker_iptables_enabled: "true"

> inventory/test/group_vars/k8s-cluster/k8s-cluster.yml
	dns_mode: manual
	manual_dns_server: 168.126.63.1

```



#### 2. nvidia-device-plugin

```
kubectl create -f nvidia-device-plugin.yml
```
or

```
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.6.0/nvidia-device-plugin.yml
```

