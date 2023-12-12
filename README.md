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


- CrossPlane  第五周: 基础设施即代码
- 