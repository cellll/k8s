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



##### Metric

* CPU Usage
	* node\_cpu\_seconds_total
	* (%) : 


* Memory Usage
	* node\_memory\_MemTotal\_bytes - node\_memory\_MemFree\_bytes - node\_memory\_Buffers\_bytes - node\_memory\_Cached\_bytes - node\_memory\_Slab\_bytes
	
	* (%) : 


* Disk Read Bytes (bytes)
	* node\_disk\_read\_bytes\_total
 

* Disk Written Bytes (bytes)
 	* node\_disk\_written\_bytes\_total


* Network Receive Bytes (bytes)
	* node\_network\_receive\_bytes\_total


* Network Transmit Bytes (bytes)
	* node\_network\_transmit\_bytes\_total


* GPU Utilization Usage (%)
	* DCGM\_FI\_DEV\_GPU\_UTIL


* GPU Memory Usage
	* DCGM\_FI\_DEV\_FB\_USED
	* (%) : DCGM\_FI\_DEV\_FB\_USED / ( DCGM\_FI\_DEV\_FB\_USED + DCGM\_FI\_DEV\_FB\_FREE )

