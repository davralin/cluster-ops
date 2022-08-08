# Kubernetes Operations

## Adding a new master

On existing master:

* kubeadm init phase upload-certs --upload-certs
* kubeadm token create

On new master:

* kubeadm config images pull
* kubeadm join <control-plane>:6443 --discovery-token-unsafe-skip-ca-verification --token $token --control-plane --certificate-key $cert
* Remove taint from master-node to allow scheduling pods there
* kubectl taint nodes --all node-role.kubernetes.io/master-

## Deleting a master

* kubectl delete node $nodename
* exec into a etcd-container in kube-system, run:

** etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key member list -w table
** Find the id of the server to be removed, and execute:
** etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key member remove $id

## Adding a new worker

On existing master:

* kubeadm init phase upload-certs --upload-certs
* kubeadm token create

On new worker:

* kubeadm config images pull
* kubeadm join <control-plane>:6443 --discovery-token-unsafe-skip-ca-verification --token $token --certificate-key $cert

On existing master, after successfull join:

* kubectl label node $node node-role.kubernetes.io/worker=worker

## Deleting a worker

* kubectl delete node $nodename
