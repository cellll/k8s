### Kubernetes : Kubespray + nvidia-device-plugin + Helm (prometheus)
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


#### 3. Helm - prometheus

```
1. StorageClass, PV, PVC 생성 

- Prometheus 적재 노드 변경 
> helm/prometheus/volumes_templates/persistentvolume.yaml
	nodeAffinity:
	  required:
	    nodeSelectorTerms:
	    - matchExpressions:
	      - key: kubernetes.io/hostname
	        operator: In
	        values:
	        - <PROMETHEUS_STORE_NODE>
	        

- 생성
> kubectl create -f helm/prometheus/volumes_templates/

> kubectl get sc -A

NAME            PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-storage   kubernetes.io/no-provisioner   Retain          WaitForFirstConsumer   false                  47m

> kubectl get pv -A

NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS    REASON   AGE
pv-prometheus   50Gi       RWX            Retain           Bound    default/pvc-prometheus   local-storage            91m

> kubectl get pvc -A

NAMESPACE   NAME             STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS    AGE
default     pvc-prometheus   Bound    pv-prometheus   50Gi       RWX            local-storage   92m


2. Prometheus, Node Exporter, DCGM Exporter 실행 
 
> helm install <RELEASE_NAME> helm/prometheus
> kubectl get pod -A

NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       w-kube-state-metrics-6bb76b8f7c-vncwh         1/1     Running   0          99m
default       w-prometheus-dcgm-exporter-p6jrj              1/1     Running   0          99m
default       w-prometheus-node-exporter-2jfmx              1/1     Running   0          99m
default       w-prometheus-server-865496b66b-gm8cs          2/2     Running   0          99m

> kubectl get svc -A

NAMESPACE     NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
default       kubernetes                   ClusterIP   10.233.0.1      <none>        443/TCP        127m
default       w-kube-state-metrics         ClusterIP   10.233.44.145   <none>        8080/TCP       100m
default       w-prometheus-dcgm-exporter   ClusterIP   10.233.46.32    <none>        9400/TCP       100m
default       w-prometheus-node-exporter   ClusterIP   None            <none>        9100/TCP       100m
default       w-prometheus-server          NodePort    10.233.54.43    <none>        80:32700/TCP   100m

> http://<NODE_IP>:32700

```



---






### Helm : Prometheus, Node Exporter, DCGM Exporter
---

##### 실행

	$ helm install <RELEASE_NAME> .
	
	$ kubectl get pod 
	
	NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
	default       d-kube-state-metrics-589b6d55cd-f552q      1/1     Running   0          108s
	default       d-prometheus-dcgm-exporter-6zv6f           1/1     Running   0          108s
	default       d-prometheus-dcgm-exporter-qfmv4           1/1     Running   0          108s
	default       d-prometheus-node-exporter-lvvtm           1/1     Running   0          108s
	default       d-prometheus-node-exporter-mt8g7           1/1     Running   0          108s
	default       d-prometheus-server-7749d9f645-46tqb       2/2     Running   0          108s
	
	$ kubectl get svc
	
	NAMESPACE     NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
	default       d-kube-state-metrics         ClusterIP   10.233.11.109   <none>        8080/TCP                 8m1s
	default       d-prometheus-dcgm-exporter   ClusterIP   10.233.37.235   <none>        9400/TCP                 8m1s
	default       d-prometheus-node-exporter   ClusterIP   None            <none>        9100/TCP                 8m1s
	default       d-prometheus-server          NodePort    10.233.36.239   <none>        80:32700/TCP             8m1s
		
        
> http://IP_ADDR:32700


---

##### Host Metric

> "node" -> "kubernetes_node"

* CPU Usage
	* node\_cpu\_seconds_total
	* **example (%)** : 100 - (avg by (kubernetes_node) (irate(node\_cpu\_seconds\_total{mode="idle"}[1m])) * 100)


* Memory Usage
	* node\_memory\_MemTotal\_bytes - node\_memory\_MemFree\_bytes - node\_memory\_Buffers\_bytes - node\_memory\_Cached\_bytes - node\_memory\_Slab\_bytes
	
	* **example (%)** : ((node_memory\_MemTotal\_bytes - avg\_over\_time(node\_memory\_MemFree\_bytes[1m]) -  avg\_over\_time(node\_memory\_Buffers\_bytes[1m]) - avg\_over\_time(node\_memory\_Cached\_bytes[1m]) - avg\_over\_time(node\_memory\_Slab\_bytes[1m])) / node\_memory\_MemTotal\_bytes) * 100


* Disk Read Bytes (bytes)
	* node\_disk\_read\_bytes\_total
 	* **example (bytes)** : rate(node\_disk\_read\_bytes\_total[1m])

* Disk Written Bytes (bytes)
 	* node\_disk\_written\_bytes\_total
 	* **example (bytes)** : rate(node\_disk\_written\_bytes\_total[1m])

* Network Receive Bytes (bytes)
	* node\_network\_receive\_bytes\_total
	* **example (bytes)** : (rate(node\_network\_receive\_bytes\_total{device="\<NET_INTERFACE\>"}[1m]))

* Network Transmit Bytes (bytes)
	* node\_network\_transmit\_bytes\_total
	* **example (bytes)** : (rate(node\_network\_transmit\_bytes\_total{device="\<NET_INTERFACE\>"}[1m]))

* GPU Utilization Usage (%)
	* DCGM\_FI\_DEV\_GPU\_UTIL
	* **example (%)** : max\_over\_time(DCGM\_FI\_DEV\_GPU\_UTIL[1m])

* GPU Memory Usage
	* DCGM\_FI\_DEV\_FB\_USED
	* **example (%)** : max\_over\_time(DCGM\_FI\_DEV\_FB\_USED[1m]) / (max\_over\_time(DCGM\_FI\_DEV\_FB\_USED[1m]) + min\_over\_time(DCGM\_FI\_DEV\_FB\_FREE[1m]))



##### Container Metric

* CPU Usage
	* container\_cpu\_usage\_seconds\_total
	* **example (%)** : sum by (container_name) (irate(container\_cpu\_usage\_seconds\_total{container\_name=<CONTAINER_NAME>}[2m])) * 100
	
* Memory Usage
	* container\_memory\_usage\_bytes
	* **example (%)** : (max\_over\_time(container\_memory\_usage\_bytes{container\_name="hi1"}[15s]) / on(kubernetes\_io\_hostname) group_left() machine\_memory\_bytes) * 100

* Disk Read Bytes
	* container\_network\_receive\_bytes\_total
	* **example (bytes) hostNetwork: false** : rate(container\_network\_receive\_bytes\_total{pod=<CONTAINER_NAME>,interface="eth0"}[1m])
	* **example (bytes) hostNetwork: true** : rate(container\_network\_receive\_bytes\_total{pod=<CONTAINER_NAME>,kubernetes\_io\_hostname="\<SERVER_HOSTNAME\>",interface="\<NET\_INTERFACE\>"}[1m])

* Disk Written Bytes
	* container\_network\_transmit\_bytes\_total
	* **example (bytes) hostNetwork: false** : rate(container\_network\_transmit\_bytes\_total{pod=<CONTAINER_NAME>,interface="eth0"}[1m])
	* **example (bytes) hostNetwork: true** : rate(container\_network\_transmit\_bytes\_total{pod=<CONTAINER_NAME>,kubernetes\_io\_hostname="\<SERVER_HOSTNAME\>",interface="\<NET\_INTERFACE\>"}[1m])

* Network Receive Bytes
	* container\_fs\_reads\_bytes\_total
	* **example (bytes)** : rate(container\_fs\_reads\_bytes\_total{kubernetes\_io\_hostname="\<SERVER_HOSTNAME\>",container\_name=<CONTAINER_NAME>}[1m])


* Network Transmit Bytes
	* container\_fs\_writes\_bytes\_total
	* **example (bytes)** : rate(container\_fs\_writes\_bytes\_total{kubernetes\_io\_hostname="\<SERVER_HOSTNAME\>",container\_name=<CONTAINER_NAME>}[1m])
