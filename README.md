# csye7125-azure-Project
#### Team Information
| Name  | NEU ID | Email Address
| ------------- | ------------- | ------------- |
| Achira Shah  | 001409351  | shah.ac@northeastern.edu |
| Apurva Mathur  | 001088100  | mathur.ap@northeastern.edu |
| Boran Yildirim | 001054080 | yildirim.b@northeastern.edu |


cd resource
terraform apply
cd stateStorage
terraform apply
cd aksCluster
terraform apply
--test--
terraform output kube_config > ~/.kube/aksconfig
export KUBECONFIG=~/.kube/aksconfig
kubectl get nodes

cd rdsService
terraform apply
