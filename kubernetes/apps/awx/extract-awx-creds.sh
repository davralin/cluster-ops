#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-awx}"

TASK_POD=$(kubectl -n "$NAMESPACE" get pods \
  -l app.kubernetes.io/name=awx-task \
  -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n "$NAMESPACE" "$TASK_POD" -i -- awx-manage shell <<'PYEOF'
import json, os
os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
from awx.main.models import Credential
from awx.main.utils.encryption import decrypt_value, get_encryption_key, is_encrypted

for c in Credential.objects.iterator():
    decrypted = {}
    for k, v in c.inputs.items():
        if is_encrypted(v):
            key = get_encryption_key(k, pk=c.pk)
            decrypted[k] = decrypt_value(key, v)
        else:
            decrypted[k] = v
    print(json.dumps({
        "id": c.id,
        "name": c.name,
        "kind": c.credential_type.name if c.credential_type_id else None,
        "inputs": decrypted,
    }, indent=2, default=str))
    print("---")
PYEOF
