# Upgrading major version of bitnami postgresql instances.

## All credit goes to: https://github.com/bitnami/charts/issues/8025#issuecomment-964906018

## Please note that I switched to using cloudnative-pg.io, which handles this much better - so I don't keep this guide up to date.

### This example is from upgrading from postgresql14 to 15.

1. Update the helm-release
   Update to the new major-version-image, set `primary.containerSecurityContext.runAsUser=0` and `diagnosticMode.enabled=true`.
2. Once the pod has restarted, exec into it, ensure the new version is active `postgres --version`.
3. `. /opt/bitnami/scripts/libos.sh`
4. `ensure_group_exists postgres -i 1001`
5. `ensure_user_exists postgres -i 1001 -g postgres`
6. `mv /bitnami/postgresql/data /bitnami/postgresql/olddata`
7. `mkdir -p /bitnami/postgresql/data; mkdir -p /bitnami/postgresql/oldbin`
8. `cd /tmp/`
9. Download the application-package from the *previous* release you upgraded from, check upstream Dockerfile.
`apt update && apt install curl -y && curl --remote-name https://downloads.bitnami.com/files/stacksmith/postgresql-14.5.0-17-linux-${OS_ARCH}-debian-11.tar.gz`
10. `cd /bitnami/postgresql/oldbin`
11. `tar --extract --directory . --file /tmp/postgresql-14.5.0-17-linux-${OS_ARCH}-debian-11.tar.gz`
12. `mv postgresql-14.5.0-linux-${OS_ARCH}-debian-11/files/postgresql/bin/* .`
13. `chown -R postgres:postgres /bitnami/postgresql/data /bitnami/postgresql/olddata`
14. `gosu postgres initdb -E UTF8 -D /bitnami/postgresql/data -U postgres`
15. `cd /tmp; rm /bitnami/postgresql/olddata/postmaster.pid`
16. `cp /bitnami/postgresql/data/postgresql.conf /bitnami/postgresql/olddata/; cp /bitnami/postgresql/data/pg_hba.conf /bitnami/postgresql/olddata/; chown -R postgres:postgres /bitnami/postgresql/data /bitnami/postgresql/olddata`
17. Start the "old" server: `gosu postgres /bitnami/postgresql/oldbin/pg_ctl start -w -D /bitnami/postgresql/olddata/`
18. After successfull start, stop it: `gosu postgres /bitnami/postgresql/oldbin/pg_ctl stop -w -D /bitnami/postgresql/olddata/`
19. `gosu postgres pg_upgrade -b /bitnami/postgresql/oldbin -B /opt/bitnami/postgresql/bin -d /bitnami/postgresql/olddata -D /bitnami/postgresql/data --socketdir=/tmp`
20. `./delete_old_cluster.sh`
21. Remove `primary.containerSecurityContext.runAsUser=0` and `diagnosticMode.enabled=true` from your helm-release.
