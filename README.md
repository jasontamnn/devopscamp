## 训练营课程大作业

1. 使用 Terraform 开通一台腾讯云 CVM, 安装 K3s(集群 1), 并在集群 1 内安装 Jenkins、Argo CD
2. 书写 Terraform lac 代码: 开通两台腾讯云 CVM, 分别安装 K3s(集群 2、集群 3), 并实现以下要求:
- 使用集群 1 作为 Terraform Kubernetes backend 后端存储
- 将 laC 源码存储在 GitHub 代码仓库中
- 在集群 1 的 Jenkins 中配置流水线, 实现在 lac 代码变更时自动触发变更 (Jenkinsfile)

3. 在集群 1 的 Argo CD 实例中添加集群 2、3
4. 使用一个 ApplicationSet +List Generators 在集群 2、集群 3 内的 default 命名空间下同时部署示例应用 Bookinfo(Helm Chart 源码见: iac/lastwork/bookinfo)
5. 示例应用部署完成后，实现以下架构：

![](https://static001.infoq.cn/resource/image/22/e5/2227cafc5cd57c32ec7babf6ceab95e5.png)

## 备注

这是一个理想的多云灾备部署场景, 集群 1、2、3 可能分别部署在不同云厂商。集群 1 的 Proxy 作为流量入口对外提供服务，对部署在集群 2 和集群 3 的无状态示例应用 Bookinfo 做负载均衡。

----

### 1. 使用Terraform搭建集群1环境(helm, argocd, jenkins, crossplane provider)
```
terraform init
terraform apply --auto-approve
```

等待各个应用部署完成后查看状态

```
kubectl get pods -A
NAMESPACE           NAME                                                READY   STATUS    RESTARTS   AGE
kube-system         coredns-8b9777675-gklls                             1/1     Running   0          3d18h
kube-system         svclb-ingress-nginx-controller-08928445-jkqmc       2/2     Running   0          3d18h
kube-system         local-path-provisioner-69dff9496c-8ks9w             1/1     Running   0          3d18h
kube-system         metrics-server-854c559bd-8c9pc                      1/1     Running   0          3d18h
ingress-nginx       ingress-nginx-controller-7cdfb9988c-h9pvk           1/1     Running   0          3d18h
crossplane-system   crossplane-rbac-manager-999f6f89d-5df8q             1/1     Running   0          3d18h
crossplane-system   crossplane-576484d998-kbtmg                         1/1     Running   0          3d18h
crossplane-system   provider-terraform-cd0c1afe87e6-568b4bdc5d-l2hhg    1/1     Running   0          3d18h
argocd              argocd-redis-95b75987f-vgdtf                        1/1     Running   0          3d18h
argocd              argocd-applicationset-controller-599fd8d8b5-7plzd   1/1     Running   0          3d18h
argocd              argocd-notifications-controller-6b7d4b497d-gqlcn    1/1     Running   0          3d18h
argocd              argocd-dex-server-849f8dd7f7-k65s4                  1/1     Running   0          3d18h
argocd              argocd-application-controller-0                     1/1     Running   0          3d18h
argocd              argocd-server-5bfcdcffb8-2wfzf                      1/1     Running   0          3d18h
argocd              argocd-repo-server-5d66f6755c-tz56c                 1/1     Running   0          3d18h
jenkins             jenkins-0                                           2/2     Running   0          3d18h
default             haproxy-deployment-76556fc989-tj5fk                 1/1     Running   0          18m
```
---

### 2. 登入Jenkins配置iac流水线任务

#### 2.1 创建Multibranch Pipeline任务

![](/img/1.png)

#### 2.2 配置Github地址以及Jenkinsfile目录(github-personal-token在terraform apply阶段已经放置在集群中)

![](/img/2.png)

#### 2.3 等待Jenkins进行仓库扫描

![](/img/4.png)

#### 2.4 配置Github Webhook

![](/img/5.png)

![](/img/6.png)

#### 2.5 等待触发流水线执行,并创建出两台cvm以及两个k3s集群

![](/img/7.png)

![](/img/8.png)

---

### 3.配置ArgoCD

#### 3.1  等待集群部署完成后, 查看状态

```
$ kubectl get workspace

NAME    READY   SYNCED   AGE
k3s-3   True    False    2d21h
k3s-2   True    False    2d21h
```

#### 3.2 获取config.yaml文件,并通过argocli添加到argocd中

```
$ argocd cluster add default --cluster-endpoint=config-2.yaml --kubeconfig=config-2.yaml --name=k8s-2

WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `default` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0002] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0002] ClusterRole "argocd-manager-role" created    
INFO[0002] ClusterRoleBinding "argocd-manager-role-binding" created 
INFO[0007] Created bearer token secret for ServiceAccount "argocd-manager" 
WARN[0007] Failed to invoke grpc call. Use flag --grpc-web in grpc calls. To avoid this warning message, use flag --grpc-web. 
Cluster 'https://119.28.41.231:6443' added

$ argocd cluster add default --cluster-endpoint=config-3.yaml --kubeconfig=config-3.yaml --name=k8s-3

WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `default` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0002] ClusterRole "argocd-manager-role" created    
INFO[0002] ClusterRoleBinding "argocd-manager-role-binding" created 
INFO[0007] Created bearer token secret for ServiceAccount "argocd-manager" 
WARN[0007] Failed to invoke grpc call. Use flag --grpc-web in grpc calls. To avoid this warning message, use flag --grpc-web. 
Cluster 'https://43.129.229.34:6443' added
```

![](/img/11.png)

#### 3.3 打上label use=prod, 并查看部署情况

![](/img/10.png)

![](/img/12.png)

---

### 4. 集群 1 的 HA Proxy 作为流量入口对外提供服务，对部署在集群 2 和集群 3 的无状态示例应用 Bookinfo 做负载均衡

```
├── cluster2-endpoint.yaml 
├── cluster2-svc.yaml
├── cluster3-endpoint.yaml
├── cluster3-svc.yaml
├── haproxy-cm.yaml
├── haproxy-deployment.yaml
└── haproxy-ingress.yaml
```

通过HA Proxy实现流量负载均衡 (加权轮询)并且集群 1 感知集群 2 和集群 3 服务健康状态, 并实现 Proxy 自动故障转移.

#### 4.1 查看Product Page的日志, 是否有心跳检查:

![](/img/13.png)

#### 4.2 此时销毁其中一台cvm, 观察Proxy是否有自动故障转移.

![](/img/15.png)

![](/img/14.png)

![](/img/16.png)