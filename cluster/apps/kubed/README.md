# this will sync this secret to all namespaces

* kubectl -n cert-manager annotate secret <secret-name> kubed.appscode.com/sync=""
