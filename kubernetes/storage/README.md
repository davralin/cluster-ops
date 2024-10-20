## Cleanup disks

````yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: disk-wipe
  namespace: kube-system
spec:
  restartPolicy: Never
  nodeName: <storage-node-name>
  containers:
  - name: disk-wipe
    image: busybox:1.37.0
    securityContext:
      privileged: true
    command: ["/bin/sh", "-c", "dd if=/dev/zero bs=1M count=100 oflag=direct of=<device>"]
````