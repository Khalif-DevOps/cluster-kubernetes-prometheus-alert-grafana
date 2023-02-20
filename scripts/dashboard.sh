#!/bin/bash
#
# Déploie le tableau de bord Kubernetes lorsqu'il est activé dans settings.yaml

set -euxo pipefail

config_path="/vagrant/configs"

DASHBOARD_VERSION=$(grep -E '^\s*dashboard:' /vagrant/settings.yaml | sed -E 's/[^:]+: *//')
if [ -n "${DASHBOARD_VERSION}" ]; then
  while sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'En attente que le serveur de métriques soit prêt...'
    sleep 5
  done
  echo 'Le serveur de métriques est prêt. Installation du tableau de bord...'

  sudo -i -u vagrant kubectl create namespace kubernetes-dashboard

  echo "Création de l'utilisateur du tableau de bord..."

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  echo "Déploiement du tableau de bord..."
  sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"

  sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}" >> "${config_path}/token"
  echo "Le jeton suivant a également été enregistré dans : configs/token"
  cat "${config_path}/token"
  echo "
Utilisez-le pour vous connecter à:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
"
fi
