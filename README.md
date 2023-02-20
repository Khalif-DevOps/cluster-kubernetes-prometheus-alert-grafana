# Vagrantfile et scripts pour automatiser la configuration de Kubernetes à l'aide de Kubeadm

## Documentation

Version actuelle de k8s : 1.26
## Conditions préalables

1. Configuration de vagrant
2. Poste de travail 8 Gig + RAM car les Vms utilisent 3 vCPUS et 4+ Go de RAM

## Afficher le cluster

Pour provisionner le cluster, exécutez les commandes suivantes.

```shell
cd cluster-kubernetes-prometheus-alert-grafana
vagrant up
```
## Définir la variable de fichier Kubeconfig

```shell
cd cluster-kubernetes-prometheus-alert-grafana
cd configs
export KUBECONFIG=$(pwd)/config
```

ou vous pouvez copier le fichier de configuration dans le répertoire .kube.

```shell
cp config ~/.kube/
```

## Installer le tableau de bord Kubernetes

Le tableau de bord est automatiquement installé par défaut, mais il peut être ignoré en commentant la version du tableau de bord dans _settings.yaml_ avant d'exécuter `vagrant up`.

Si vous ignorez l'installation du tableau de bord, vous pouvez le déployer plus tard en l'activant dans _settings.yaml_ et en exécutant ce qui suit :

```shell
vagrant ssh -c "/vagrant/scripts/dashboard.sh" master
```
## Accès au tableau de bord Kubernetes

Pour obtenir le jeton de connexion, copiez-le depuis _config/token_ ou exécutez la commande suivante :

```shell
kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}"
```

Proxy le tableau de bord :

```shell
kubectl proxy
```

Ouvrez le site dans votre navigateur :

```shell
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard
```

## Pour arrêter le cluster,

```shell
vagrant halt
```

## Pour redémarrer le cluster,

```shell
vagrant up
```

## Pour détruire le cluster,

```shell
vagrant destroy -f
```









## Créer un espace de noms Kubernetes pour tous nos composants de surveillance

kubectl create namespace monitoring

## Créer une politique RBAC avec les read access groupes d'API requis et lier la politique à l'espace de noms :  monitoring

kubectl create -f clusterRole.yaml

kubectl create -f config-map.yaml

kubectl create  -f prometheus-deployment.yaml 

kubectl create -f prometheus-service.yaml --namespace=monitoring

