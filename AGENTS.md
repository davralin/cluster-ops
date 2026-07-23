# AGENTS.md — cluster-ops conventions

GitOps Kubernetes cluster: Talos Linux, Flux, Cilium, Rook-Ceph, SOPS/Age.

## Commit & PR Style

- **Atomic commits** — each commit is one logical, self-contained change
- **Atomic PRs** — each pull request contains only related, grouped commits
- Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`
  - `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`
- Keep commit messages concise; use the body for detail when needed
- Squash/rebase before merging if intermediate commits aren't meaningful
- **PR descriptions should be brief** — let the code speak for itself. Don't write a blog post for every pull request

## Repository Structure

```
kubernetes/
├── apps/          # Application deployments (one dir per app or namespace group)
├── clusters/      # Cluster-level Flux Kustomizations (postBuild variable substitution)
├── core/          # Core infra (Cilium, cert-manager, HAProxy, Flux)
├── monitoring/    # Prometheus stack, alerting rules
├── security/      # Admission policies (Kyverno)
└── storage/       # Rook-Ceph cluster configuration
ansible/           # Host provisioning playbooks (AWX)
talos/             # Talos Linux machine configs
```

## App Deployment Patterns

### Prefer app-template built-ins

Before creating separate resource files, check if app-template handles it natively:
- **RBAC** → `rbac.roles` + `rbac.bindings`
- **ConfigMaps** → `configMaps` (inline data; named `<fullnameOverride>` when there is only one, `<fullnameOverride>-<key>` when there are multiple)
- **Raw resources** → `rawResources` (CiliumNetworkPolicies, etc.)
- **ServiceAccounts** → `serviceAccount: { <name>: {} }`

**Chart selection hierarchy:**
1. Dedicated upstream Helm charts — when available and they expose the values we need (securityContext, podSecurityContext are common gaps)
2. bjw-s app-template — for most apps
3. dysnix raw chart — for operator CRDs (VolSync ReplicationSources, CNPG Clusters, Prometheus Probes, etc.) that need their own HelmRelease lifecycle

**Chart sources:**
- OCI charts → use `OCIRepository` + `chartRef` in HelmRelease (per-app `oci-repository.yaml`), NOT `HelmRepository` with `type: oci`
- Non-OCI charts → use `HelmRepository` in `kubernetes/core/charts/` + `chart.spec` in HelmRelease

### Standalone app (own namespace)

Directory: `kubernetes/apps/<appname>/`

Required files:
- `helm-release.yaml` — HelmRelease using bjw-s app-template
- `kustomization.yaml` — lists all resource files
- `namespace.yaml` — Namespace manifest
- `networkpolicy.yaml` — default-deny NetworkPolicy
- `probes.yaml` — blackbox exporter Probe (wrapped in dysnix raw chart)
- `pvc.yaml` — PersistentVolumeClaim (if app has persistent data)
- `volsync.yaml` — VolSync Restic backup (if app has persistent data)

If app needs a database, add:
- `helm-release-db-v18.yaml` — CNPG PostgreSQL cluster (PG version in filename)
- `database-secret.yaml` — SOPS-encrypted secret with DB credentials + S3 backup keys

If app needs secrets, add:
- `secret.yaml` — SOPS-encrypted Secret manifest

### Grouped apps (shared namespace)

Example: `kubernetes/apps/media/<appname>/`

- Apps share the parent namespace (e.g. `media`, defined in `kubernetes/apps/media/namespace.yaml`)
- Shared default-deny at parent level (`kubernetes/apps/media/networkpolicy.yaml`)
- Each sub-app has its own directory with `helm-release.yaml` and `kustomization.yaml`
- Parent `kustomization.yaml` lists all sub-app directories + shared resources

### Secrets pattern

Secrets use SOPS with Age encryption. When adding a new app that needs secrets:

1. Create `secret.yaml` (or `database-secret.yaml`) with **dummy placeholder values** — NOT real credentials
2. Do NOT add it to `kustomization.yaml` yet
3. The file serves as a template — fill in real values, encrypt with `sops -e -i secret.yaml`, then add to `kustomization.yaml`

This prevents accidental deployment of unencrypted secrets. CNPG won't bootstrap and Flux won't apply resources not listed in kustomization.yaml.

## HelmRelease Template

Every app uses bjw-s app-template. Copy from an existing app (e.g. `mealie`) and modify.

For OCI-sourced upstream charts, add an `oci-repository.yaml` to the app directory and use `chartRef` instead of `chart.spec`:

```yaml
# oci-repository.yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: appname
  namespace: flux-system
spec:
  interval: 10m
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
  ref:
    tag: 1.0.0
  url: oci://ghcr.io/example/charts/appname
```

```yaml
# helm-release.yaml (chartRef variant)
spec:
  chartRef:
    kind: OCIRepository
    name: appname
    namespace: flux-system
```

For app-template (non-OCI), use the standard `chart.spec` block:

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &name appname
  namespace: flux-system          # ALWAYS flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: app-template
      version: 5.0.1             # Renovate manages this
      sourceRef:
        kind: HelmRepository
        name: bjw-s-charts
        namespace: flux-system
      interval: 30m
  driftDetection:
    mode: enabled
  targetNamespace: appname        # Actual namespace (or "media" for media apps)
  install:
    createNamespace: true
    remediation:
      retries: 10
  upgrade:
    remediation:
      retries: 10
  values:
    fullnameOverride: *name
    defaultPodOptions:
      automountServiceAccountToken: false
      enableServiceLinks: false
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        fsGroupChangePolicy: "OnRootMismatch"
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
    controllers:
      appname:
        containers:
          appname:
            image:
              repository: ghcr.io/example/app
              tag: v1.0.0@sha256:abc123   # Always pin digest — Renovate updates these
            env:
              TZ: "${TIMEZONE}"
            probes:
              liveness: &probes
                enabled: true
              readiness: *probes
              startup: *probes
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities:
                drop:
                  - ALL
            resources:
              requests:
                cpu: 10m
              limits:
                memory: 512Mi
    service:
      appname:
        controller: *name
        ports:
          http:
            port: &port 8080
    ingress:
      appname:
        enabled: true
        annotations:
          haproxy-ingress.github.io/allowlist-source-range: "${HAPROXY_WHITELIST}"
          haproxy-ingress.github.io/ssl-redirect: "true"
          haproxy-ingress.github.io/config-backend: |
            http-response set-header Strict-Transport-Security "max-age=31536000"
            http-response set-header X-Frame-Options DENY
            http-response set-header X-Content-Type-Options nosniff
            http-response set-header Referrer-Policy strict-origin-when-cross-origin
        hosts:
          - host: &host "appname.${SECRET_DEFAULT_DOMAIN}"
            paths:
              - path: /
                service:
                  identifier: appname
                  port: http
        tls:
          - hosts:
              - *host
    persistence:
      config:
        enabled: true
        existingClaim: appname
    networkpolicies:
      appname:
        enabled: true
        controller: *name
        policyTypes:
          - Egress
          - Ingress
        rules:
          egress: []              # Add specific egress rules as needed
          ingress:
            - from:
                - namespaceSelector:
                    matchLabels:
                      kubernetes.io/metadata.name: haproxy-controller
                  podSelector:
                    matchLabels:
                      app.kubernetes.io/name: haproxy-ingress
              ports:
                - port: *port
```

## YAML Anchors — Mandatory Convention

Always use YAML anchors for DRY references:
- `&name` on `metadata.name` → `*name` in `fullnameOverride`, `controller`, networkpolicy controller
- `&port` on service port → `*port` in networkpolicy ingress port
- `&host` on ingress host → `*host` in TLS hosts
- `&probes` on liveness probe → `*probes` for readiness and startup
- `&namespace` when referencing namespace in raw chart resources

## Security — Non-negotiable

### Pod-level (defaultPodOptions.securityContext)

Always include: `automountServiceAccountToken: false`, `enableServiceLinks: false`, `runAsUser: 1000`, `runAsGroup: 1000`, `fsGroup: 1000`, `fsGroupChangePolicy: "OnRootMismatch"`, `runAsNonRoot: true`, `seccompProfile.type: RuntimeDefault`.

**`fsGroup: 1000` and `fsGroupChangePolicy: "OnRootMismatch"` is critical for shared PVCs.** Without it, Kubernetes recursively chowns every file on the volume at every pod start. On large shared volumes like the `media` PVC, this blocks container startup for minutes. Never omit this setting.

### Container-level (containers.*.securityContext)

Always include: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` (set false only if app truly requires it), `capabilities.drop: [ALL]`.

**Prefer `readOnlyRootFilesystem: true` with emptyDir mounts** over setting it to `false`. If an app writes to `/tmp`, `/cache`, or other runtime directories, add `emptyDir` volumes for those paths instead of disabling read-only root. Only set `false` as a last resort when the app writes to unpredictable locations across the filesystem.

**Do NOT add `tmp` emptyDir mounts preemptively.** Only add emptyDir volumes when the app is known to need them (e.g. it crashes without write access to a specific path). Don't speculatively add `/tmp` emptyDir "just in case" — if the app doesn't need it, don't include it.

### Persistence naming convention

bjw-s app-template auto-mounts volumes to `/<key>` when `globalMounts` is omitted. Use the mount directory name as the persistence key to avoid redundant path config:

```yaml
# Good — key matches mount path, no globalMounts needed
persistence:
  data:
    enabled: true
    existingClaim: appname
  tmp:
    enabled: true
    type: emptyDir

# Only use globalMounts when the key doesn't match the path
persistence:
  config:
    enabled: true
    existingClaim: appname
    globalMounts:
      - path: /app/data
```

### Network Policies

1. **Default-deny per namespace** — `networkpolicy.yaml` in every app/namespace directory
2. **Per-app NetworkPolicy** — inside HelmRelease `values.networkpolicies`
3. **CNPG databases** also need a CiliumNetworkPolicy for kube-apiserver access (port 6443)

### Default-deny template

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: appname
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### Common egress rules

**Egress order**: Always list DNS first, then app-specific rules. DNS is the most fundamental dependency.

**Least-privilege egress**: Only allow the egress an app actually needs. If it only talks to in-cluster services, only allow those specific pod selectors. Don't add broad internet egress unless the app genuinely requires external access.

**Cross-namespace podSelector specificity**: When targeting pods in another namespace, use enough labels to ensure the selector matches only the intended pod. Prefer multiple labels over a single one:
```yaml
podSelector:
  matchLabels:
    app.kubernetes.io/controller: appname
    app.kubernetes.io/instance: namespace-appname
    app.kubernetes.io/name: namespace-appname
```

### RBAC (Roles + Bindings)

Apps that need Kubernetes API access require a ServiceAccount, Role/ClusterRole, and RoleBinding. Use app-template built-ins. Note: app-template v5 uses `identifier` references, not `serviceAccountRef`:

```yaml
serviceAccount:
  hermes-agent: {}
rbac:
  roles:
    hermes-agent:
      type: Role
      rules:
        - apiGroups: [""]
          resources: ["pods"]
          verbs: ["get", "list", "delete"]
  bindings:
    hermes-agent:
      type: RoleBinding
      roleRef:
        identifier: hermes-agent   # references rbac.roles.hermes-agent
      subjects:
        - identifier: hermes-agent # references serviceAccount.hermes-agent
```

Also set `automountServiceAccountToken: true` in `defaultPodOptions`.

### CiliumNetworkPolicy for kube-apiserver

Any app that needs Kubernetes API access (e.g. `automountServiceAccountToken: true`) needs a CiliumNetworkPolicy for kube-apiserver. Add via `rawResources` in the HelmRelease:
```yaml
rawResources:
  cilium-kube-api:
    manifest:
      apiVersion: cilium.io/v2
      kind: CiliumNetworkPolicy
      spec:
        endpointSelector:
          matchLabels:
            app.kubernetes.io/controller: *name
        egress:
          - toEntities:
              - kube-apiserver
            toPorts:
              - ports:
                  - port: "6443"
                    protocol: TCP
```

DNS (needed for most apps making outbound requests):
```yaml
- to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
  ports:
    - port: 53
      protocol: UDP
```

### Cross-app network policies

When adding an app that communicates with existing apps, update the existing app's network policies to allow the new traffic (egress, ingress, or both — depending on what's needed).

## Database Conventions (CNPG PostgreSQL)

File: `helm-release-db-v18.yaml` — version number tracks PostgreSQL major version.

Uses `dysnix raw` chart to deploy CNPG resources. Key patterns:
- 2 instances, `walStorage` enabled
- `barmanObjectStore` backup to S3 with `ScheduledBackup`
- Managed roles with `basic-auth` secret
- DB service hostname: `<appname>-postgres-v18-rw.<namespace>.svc.cluster.local`
- NetworkPolicy: ingress from app pods + cnpg-operator namespace + monitoring, egress to peers + DNS + S3
- CiliumNetworkPolicy: egress to kube-apiserver on port 6443
- `enablePodMonitor: "${MONITORING_PROMETHEUS}"`

## Secret Management

- Encryption: SOPS with Age (`encrypted_regex: '^(data|stringData)$'`)
- Reference in containers via `valueFrom.secretKeyRef` — **never** HelmRelease-level `valuesFrom`
- Flux variable substitution (from `global-settings` ConfigMap/Secret) for non-sensitive config: `${TIMEZONE}`, `${SECRET_DEFAULT_DOMAIN}`, `${HAPROXY_WHITELIST}`, `${STORAGE_READWRITEONCE}`, `${CLUSTER_NAME}`, `${MONITORING_PROMETHEUS}`, `${BLACKBOX_EXPORTER_URL}`, etc.

```yaml
# Referencing secrets in container env
env:
  DB_PASSWORD:
    valueFrom:
      secretKeyRef:
        name: appname-basic-auth
        key: password
```

## Ingress Conventions

- Controller: HAProxy Ingress
- Always include the standard annotations (allowlist, ssl-redirect, security headers)
- Host format: `"appname.${SECRET_DEFAULT_DOMAIN}"`
- TLS always enabled
- Use `&host` / `*host` anchors

## Monitoring

Every app with an ingress gets a blackbox exporter Probe in `probes.yaml`:
- Wrapped in `dysnix raw` HelmRelease
- `dependsOn`: `kube-prometheus-stack-crds` and `blackbox-exporter`
- Target: `"https://appname.${SECRET_DEFAULT_DOMAIN}"`

## Backup (VolSync)

Every app with persistent data gets a VolSync ReplicationSource in `volsync.yaml`:
- Wrapped in `dysnix raw` HelmRelease
- Restic to S3, `copyMethod: Direct`
- Cron schedule (stagger across apps)
- Retention: 7 daily, within 3d
- Includes NetworkPolicy for volsync mover pods (egress to DNS + S3 only)
- `dependsOn`: `volsync` and the app's HelmRelease

## Resource Conventions

- **Always set memory limits**
- **Always set CPU requests** (even small, e.g. `10m`)
- **Do NOT set CPU limits** — let pods burst (exception: GPU resources like `gpu.intel.com/i915`)

## Flux Conventions

- HelmRelease `metadata.namespace`: always `flux-system` — use `targetNamespace` for actual namespace
- `driftDetection.mode: enabled` — on every HelmRelease
- `remediation.retries: 10` — on both `install` and `upgrade`
- `interval: 30m` — on both HelmRelease and chart spec
- `install.createNamespace: true`

## File Templates

### namespace.yaml
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: appname
```

### pvc.yaml
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: appname
  namespace: appname
spec:
  storageClassName: "${STORAGE_READWRITEONCE}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### kustomization.yaml
```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - helm-release.yaml
  - namespace.yaml
  - networkpolicy.yaml
  - probes.yaml
  - pvc.yaml
  - volsync.yaml
```

## README

Update the applications table in `README.md` when adding or removing apps.

## Image Tags

Always pin with digest: `tag: v1.0.0@sha256:...`. Renovate handles updates automatically.

Always use fully qualified image references — prefix Docker Hub images with `docker.io/` (e.g. `docker.io/org/image`, not just `org/image`).

## Common Mistakes

1. **Don't put HelmRelease in app namespace** — always `namespace: flux-system` with `targetNamespace`
2. **Don't use `valuesFrom` for secrets** — use `valueFrom.secretKeyRef` in container env
3. **Don't forget default-deny NetworkPolicy** per namespace
4. **Don't forget per-app NetworkPolicy** inside HelmRelease values
5. **Don't skip probes** — every container gets liveness/readiness/startup via anchor pattern
6. **Don't forget `automountServiceAccountToken: false`** and `enableServiceLinks: false`
7. **Don't set CPU limits** (unless GPU resources)
8. **Don't forget YAML anchors** — `&name`, `&port`, `&host`, `&probes`
9. **Don't forget VolSync backup** for apps with persistent data
10. **Don't add resource files without listing them in `kustomization.yaml`** (except unencrypted secret templates)
11. **Don't commit unencrypted secrets** — use dummy values, encrypt with `sops -e -i` before adding to kustomization
12. **Don't forget TLS in ingress**
13. **Don't forget the standard HAProxy Ingress annotations**
14. **Don't forget `driftDetection.mode: enabled`**
