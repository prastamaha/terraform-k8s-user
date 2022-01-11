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

variable "kubeconfig" {
  type = string
}

variable "context" {
  type = string
}

variable "user_name" {
  type = string
}

variable "user_namespace" {
  type = string
}

variable "user_role" {
  type = string
}

provider "kubernetes" {
  config_path    = var.kubeconfig
  config_context = var.context
}

resource "tls_private_key" "user_privatekey" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "user_csr" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.user_privatekey.private_key_pem

  subject {
    common_name = var.user_name
  }
}

resource "kubernetes_certificate_signing_request_v1" "kubernetes_user_csr" {
  metadata {
    name = var.user_name
  }
  spec {
    usages      = ["client auth"]
    signer_name = "kubernetes.io/kube-apiserver-client"

    request = tls_cert_request.user_csr.cert_request_pem
  }

  auto_approve = true
}

resource "kubernetes_namespace" "kubernetes_user_namespace" {
  metadata {
    annotations = {
      name = var.user_namespace
    }
    

    name = var.user_namespace
  }
}

resource "kubernetes_secret" "kubernetes_user_tls" {
  metadata {
    name = "${var.user_name}-tls"
    namespace = var.user_namespace
  }
  data = {
    "tls.crt" = kubernetes_certificate_signing_request_v1.kubernetes_user_csr.certificate
    "tls.key" = tls_private_key.user_privatekey.private_key_pem
  }
  type = "kubernetes.io/tls"
}

resource "kubernetes_role_binding_v1" "kubernetes_user_rolebinding" {
  metadata {
    name      = "${var.user_name}-${var.user_namespace}-${var.user_role}"
    namespace = var.user_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.user_role
  }
  subject {
    kind      = "User"
    name      = var.user_name
    api_group = "rbac.authorization.k8s.io"
  }
}

output "client-certificate-data" {
  value = base64encode(kubernetes_certificate_signing_request_v1.kubernetes_user_csr.certificate)
  sensitive = true
}

output "client-key-data" {
  value = base64encode(tls_private_key.user_privatekey.private_key_pem)
  sensitive = true
}


