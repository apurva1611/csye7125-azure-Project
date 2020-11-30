app-prereq Helm chart will install following:
* Kafka
* Elasticsearch
* Fluentd
* Kibana
* Prometheus & Alertmanager
* Grafana

### Install
Run in this directory
```
helm dependency update
```
Change directory to one level up, then run
```
helm install app-prereq app-prereq
```
or
```
helm upgrade --install app-prereq app-prereq
```

### Kibana
```
kubectl port-forward <kibana-pod-name>  5601
```
Visit -> 127.0.0.1:5601 . You will see Kibana dashboard.

### Delete
```
helm delete app-prereq
```

<!-- ref
https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml
https://github.com/helm/charts/blob/master/incubator/kafka/values.yaml -->