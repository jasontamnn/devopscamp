#!/bin/bash  

setup_cli() {
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

setup_k3s() {
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
}

setup_helm_repo() {
    helm repo add jenkins https://charts.jenkins.io
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm update
}

setup_jenkins() {
    kubectl create ns jenkins
    # plugin need id(url of plugin)
    helm upgrade -i jenkins jenkins/jenkins -n jenkins --create-namespace -f /tmp/jenkins-values.yaml --version 4.6.1
    kubectl apply -f /tmp/jenkins-service-account.yaml -n jenkins
    # apply jenkins github pull secret
    kubectl apply -f /tmp/github-personal-token.yaml -n jenkins
}

setup_argocd() {
  helm upgrade --install -n argocd argocd argo/argo-cd --version 5.36.6 -f /tmp/argocd-values.yaml --create-namespace
}

setup_nginx_ingress() {
  # install ingress-nginx
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace --wait --version "4.7.2"
}

setup_crossplane() {
  helm install crossplane \
    --namespace crossplane-system \
    --create-namespace crossplane-stable/crossplane \
    --wait

  kubectl apply -f /tmp/provider.yaml -n crossplane-system
  sleep 10
  kubectl apply -f /tmp/providerConfig.yaml
}

main () {
  setup_cli
  setup_k3s
  setup_helm_repo
  setup_nginx_ingress
  setup_jenkins
  setup_argocd
  setup_crossplane
}

main