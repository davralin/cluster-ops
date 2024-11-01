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

From toolbox:
````bash
To display a list of messages:

ceph crash ls

If you want to read the message:

ceph crash info <id>

then:

ceph crash archive <id>

or:

ceph crash archive-all
````
# https://forum.proxmox.com/threads/health_warn-1-daemons-have-recently-crashed.63105/