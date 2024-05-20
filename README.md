A collection of scripts to initialize my remote clusters
---------------------------------------------------------



Fedora with VCluster running Kafka
----------------------------------
jsoehner@Jeffs-MacBook cluster-2 % ./fedora-vcluster-kafka.sh        
ERROR: flag needs an argument: --name
Creating cluster "cluster2" ...
 ✓ Ensuring node image (kindest/node:v1.30.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-cluster2"
You can now use your cluster with:

kubectl cluster-info --context kind-cluster2

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
  *** Please wait while we install Cilium... ***
🔮 Auto-detected Kubernetes kind: kind
✨ Running "kind" validation checks
✅ Detected kind version "0.23.0"
ℹ️  Using Cilium version 1.16.0-pre.2
🔮 Auto-detected cluster name: kind-cluster2
ℹ️  Detecting real Kubernetes API server addr and port on Kind
🔮 Auto-detected kube-proxy has not been installed
ℹ️  Cilium will fully replace all functionalities of kube-proxy
07:48:09 info Creating namespace vcluster-strimzi-1
07:48:09 info Detected local kubernetes cluster kind. Will deploy vcluster with a NodePort & sync real nodes
07:48:09 info Create vcluster strimzi-1...
07:48:09 info execute command: helm upgrade strimzi-1 /var/folders/_j/ld7wp5rj4t13ytlqylwym51r0000gq/T/vcluster-0.20.0-beta.1.tgz-3245999441 --kubeconfig /var/folders/_j/ld7wp5rj4t13ytlqylwym51r0000gq/T/3642006482 --namespace vcluster-strimzi-1 --install --repository-config='' --values /var/folders/_j/ld7wp5rj4t13ytlqylwym51r0000gq/T/1288051889 --values vcluster.yaml
07:48:10 done Successfully created virtual cluster strimzi-1 in namespace vcluster-strimzi-1. 
- Use 'vcluster connect strimzi-1 --namespace vcluster-strimzi-1' to access the virtual cluster
  *** Lets pause while the vcluster becomes active... ***
07:48:26 info Waiting for vcluster to come up...
07:48:28 warn vcluster is waiting, because vcluster pod strimzi-1-74879489bb-mw58c has status: Init:0/3
07:48:39 warn vcluster is waiting, because vcluster pod strimzi-1-74879489bb-mw58c has status: Init:1/3
07:48:49 warn vcluster is waiting, because vcluster pod strimzi-1-74879489bb-mw58c has status: Init:2/3
namespace/kafka created
  *** Lets add the kafka software... ***
customresourcedefinition.apiextensions.k8s.io/kafkanodepools.kafka.strimzi.io created
rolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator created
customresourcedefinition.apiextensions.k8s.io/kafkausers.kafka.strimzi.io created
customresourcedefinition.apiextensions.k8s.io/kafkatopics.kafka.strimzi.io created
customresourcedefinition.apiextensions.k8s.io/kafkaconnects.kafka.strimzi.io created
customresourcedefinition.apiextensions.k8s.io/kafkabridges.kafka.strimzi.io created
serviceaccount/strimzi-cluster-operator created
clusterrole.rbac.authorization.k8s.io/strimzi-kafka-broker created
clusterrole.rbac.authorization.k8s.io/strimzi-cluster-operator-watched created
clusterrolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator-kafka-client-delegation created
customresourcedefinition.apiextensions.k8s.io/kafkamirrormaker2s.kafka.strimzi.io created
customresourcedefinition.apiextensions.k8s.io/strimzipodsets.core.strimzi.io created
clusterrolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator created
customresourcedefinition.apiextensions.k8s.io/kafkamirrormakers.kafka.strimzi.io created
deployment.apps/strimzi-cluster-operator created
customresourcedefinition.apiextensions.k8s.io/kafkaconnectors.kafka.strimzi.io created
clusterrole.rbac.authorization.k8s.io/strimzi-cluster-operator-global created
customresourcedefinition.apiextensions.k8s.io/kafkarebalances.kafka.strimzi.io created
configmap/strimzi-cluster-operator created
customresourcedefinition.apiextensions.k8s.io/kafkas.kafka.strimzi.io created
clusterrole.rbac.authorization.k8s.io/strimzi-cluster-operator-namespaced created
rolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator-watched created
clusterrole.rbac.authorization.k8s.io/strimzi-entity-operator created
clusterrolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator-kafka-broker-delegation created
clusterrole.rbac.authorization.k8s.io/strimzi-cluster-operator-leader-election created
rolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator-leader-election created
rolebinding.rbac.authorization.k8s.io/strimzi-cluster-operator-entity-operator-delegation created
clusterrole.rbac.authorization.k8s.io/strimzi-kafka-client created
kafkanodepool.kafka.strimzi.io/controller created
kafkanodepool.kafka.strimzi.io/broker created
kafka.kafka.strimzi.io/my-cluster created
  *** Lets pause while the kafka cluster becomes active... ***
kafka.kafka.strimzi.io/my-cluster condition met
  *** Lets initialize an example of a producer and a consume... ***
kafkatopic.kafka.strimzi.io/my-topic created
kafkatopic.kafka.strimzi.io/my-topic-reversed created
deployment.apps/java-kafka-producer created
deployment.apps/java-kafka-streams created
deployment.apps/java-kafka-consumer created
  *** All Done - Enjoy... ***
jsoehner@Jeffs-MacBook cluster-2 %
