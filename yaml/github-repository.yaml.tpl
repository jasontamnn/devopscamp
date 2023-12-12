apiVersion: v1
kind: Secret
metadata:
  name: yamltoinfra
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: https://github.com/jasontamnn/devopscamp.git
  password: "${github_personal_token}" # your github personal access token
  username: jasontamnn
  insecure: "true"
  forceHttpBasicAuth: "true"
  enableLfs: "true"
