Run Head node script
Setup Cluster
Run worker node script on each node
Run kubeadm join command on each node
Import into Rancher, tunnel ssh -L  8443:localhost:443 -Nfl ubuntu 130.246.212.36
Set up Promethues + Grafana monitoring
- Create namespace
- kubectl create -f clusterRole.yaml
- kubectl create -f config-map.yml
- kubectl create -f prometheus-deployment.yml
- kubectl create -f grafana-datasource-config.yaml
- kubectl create -f grafana-deployment.yaml
- kubectl create -f  grafana-service.yaml
See Grafana dashboard either on any Node IP + port 32000 or tunnelling
Login with admin/admin and you'll be prompted to change the password
Import the Kubernetes metrics dashboard template (ID 8588)

Add Helm stable repo, repo update
helm repo add stable https://kubernetes-charts.storage.googleapis.com/

Create k8s namespace nfsprovisioner and deploy NFS via helm chart with `helm install nfs stable/nfs-server-provisioner --namespace nfsprovisioner --set=storageClass.defaultClass=true`

PostGresDB via helm chart, add helm charts, create kubernetes namespace
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install pgdatabase --namespace pgdatabase bitnami/postgresql \
--set postgresqlDatabase=jhubdb \
--set postgresqlPassword=postgres

Setup jupyterhub config file as per your requirements
Create jhub kubernetes namespace, add helm repo, and install Jhub helm chart
Create proxy secret tpken and hub's cookie secret with openssl rand -hex 32
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
helm upgrade --install jhub jupyterhub/jupyterhub --namespace jhub --version=0.9.0 --values jupyterhub-config.yaml

Configure Metallb 0.9.3 if your cloud provider doesnt provide a load balanacer for k8s cluster
Prerequisite: enable strict ARP mode by editing the kube-proxy configmap, search for IPVS, and set strictARP to true
`kubectl edit configmap -n kube-system kube-proxy`
Apply namespace yaml
Apply metallb yaml
Create secret on first install only `kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"`

