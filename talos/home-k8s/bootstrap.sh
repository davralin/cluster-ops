#!/bin/bash
talosctl gen config home-k8s https://k8s.VIP-ADDR:6443 --with-examples=false --with-docs=false --with-kubespan=false --with-cluster-discovery=false --kubernetes-version=1.28.1
