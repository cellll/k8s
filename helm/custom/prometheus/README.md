### Helm : Prometheus, Node Exporter, DCGM Exporter
---

##### 실행

	$ kubectl create -f volume_templates/storageclass.yaml
	$ kubectl create -f volume_templates/persistentvolume.yaml
	$ kubectl create -f volume_templates/persistentvolumeclaim.yaml
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
