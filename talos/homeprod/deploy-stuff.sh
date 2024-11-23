#!/bin/bash
helm install \
    cilium \
    cilium/cilium \
    --version 1.16.2 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445

helm install --create-namespace \
    flux2 \
    fluxcd-community/flux2 \
    --version 2.14.0 \
    --namespace flux-system \
    --set imageAutomationController.create=false \
    --set imageReflectionController.create=false

kubectl -n flux-system create secret generic sops-age --from-file=keys.agekey=~/.config/sops/age/keys.txt

helm install --create-namespace \
    github-davralin-cluster-ops \
    fluxcd-community/flux2-sync \
    --version 1.10.0 \
    --namespace flux-system \
    --set gitRepository.spec.url=https://github.com/davralin/cluster-ops \
    --set gitRepository.spec.ref.branch=main \
    --set kustomization.spec.path=./kubernetes/clusters/homeprod \
    --set kustomization.spec.prune=true
