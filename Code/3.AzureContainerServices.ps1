# check AzureRM module is installed
Get-Module -ListAvailable AzureRM



# log in to azure
Connect-AzureRmAccount



# create kubernetes cluster (with 2 nodes)
New-AzureRmAks -ResourceGroupName containers1 -Name mySQLK8sCluster1 -NodeCount 2



# install kubectl
az aks install-cli



# get credentials to connect to cluster
Import-AzureRmAksCredential -ResourceGroupName containers1 -Name mySQLK8sCluster1


# confirm connection to cluster by viewing nodes
kubectl get nodes



# Get AKS client ID
$aks = Get-AzureRmResource -ResourceGroupName containers1 -ResourceType Microsoft.ContainerService/managedClusters `
  -ResourceName mySQLK8sCluster1 -ApiVersion 2018-03-31
$clientid = $aks.properties.servicePrincipalProfile.clientId

# Get ACR ID
$acr = Get-AzureRmContainerRegistry -ResourceGroupName containers1 -Name TestContainerRegistry01 
$resourceid = $acr.id


# Create role to allow deployments
New-AzureRmRoleAssignment -ApplicationId $clientid -RoleDefinitionName "Reader" -Scope $resourceid


# create yaml file for deployment
echo 'apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: sqlserver
  labels:
    app: sqlserver
spec:
  replicas: 1
  template:
    metadata:
      labels:
        name: sqlserver
    spec:
      containers:
      - name: sqlserver1
        image: testcontainerregistry01.azurecr.io/devsqlimage:latest
        ports:
        - containerPort: 1433
        env:
        - name: SA_PASSWORD
          value: "Testing1122"
        - name: ACCEPT_EULA
          value: "Y"
---
apiVersion: v1
kind: Service
metadata:
  name: sqlserver-service
spec:
  ports:
  - name: sqlserver
    port: 1433
    targetPort: 1433
  selector:
    name: sqlserver
  type: LoadBalancer' > sqlserver.yml



# deploy to cluster
kubectl create -f sqlserver.yml



# view deployment
kubectl get deployments



# view pods
kubectl get pods



# view service
kubectl get service



# view dashboard
Start-AzureRmAksDashboard -ResourceGroupName containers1 -Name mySQLK8sCluster1