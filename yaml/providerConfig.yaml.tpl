apiVersion: tf.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  configuration: |
    terraform {
      required_providers {
        tencentcloud = {
          source = "tencentcloudstack/tencentcloud"
        }
      }
    }

    provider "tencentcloud" {
      secret_id  = "${secret_id}"
      secret_key = "${secret_key}"
      region     = "ap-hongkong"
    }

    terraform {
      backend "kubernetes" {
        secret_suffix     = "providerconfig-default"
        namespace         = "crossplane-system"
        in_cluster_config = true
      }
    }
