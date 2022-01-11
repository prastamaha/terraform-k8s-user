# Terraform Kubernetes User

create kubernetes user using terraform

this repository using terraform providers such as hashicorp/kubernetes and hashicorp/tls

```
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

```

This repository is suitable for creating a new user in a new namespace as a **playground**.
we can apply/destroy user and namespace easily with terraform.

## Check Variables

some variables such as context, user_name and user_role do not have default values, and will be entered manually when running terraform.

> change the variable as needed

```
cat variables.tfvars

...
kubeconfig = "~/.kube/config"
context = "kubernetes-admin@kubernetes"
user_name = "example"
user_namespace = "example-namespace"
user_role = "admin"
...

```

## Run Terraform

apply terraform resource

```
terraform init
terraform plan
terraform apply -var-file=variables.tfvars
```

get user tls cert and key

```
terraform output client-certificate-data
terraform output client-key-data
```

destroy terraform resource

```
terraform destroy -var-file=variables.tfvars
```

## Test Created User

create kubeconfig for created user

```
nano example-config

...
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: [kubernetes-cacert]
    server: [kubernetes-server]
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: example-namespace
    user: example
  name: example
current-context: "example"
users:
- name: example
  user:
    client-certificate-data: [client-certificate-data]
    client-key-data: [client-key-data]
...
```

run kubectl command using new kubeconfig

```
kubectl get po --kubeconfig=example-config
```
