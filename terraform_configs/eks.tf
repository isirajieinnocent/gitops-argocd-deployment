apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-name
spec:
  replicas: 3
  selector:
    matchLabels:
      app: release-name
  template:
    metadata:
      labels:
        app: release-name
    spec:
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: "ghcr.io/isirajieinnocent/time-printer:latest"
          ports:
            - containerPort: 8080
server:
  extraArgs:
    - --tls-cert-file=/etc/argocd/tls/argocd-server.crt
    - --tls-key-file=/etc/argocd/tls/argocd-server.key
  extraVolumeMounts:
    - name: argocd-server-tls
      mountPath: /etc/argocd/tls
      readOnly: true
  extraVolumes:
    - name: argocd-server-tls
      secret:
        secretName: argocd-server-tls
