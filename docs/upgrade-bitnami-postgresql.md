# Upgrading major version of bitnami postgresql instances.

## All credit goes to: https://github.com/bitnami/charts/issues/8025#issuecomment-964906018

### This example is from upgrading from postgresql14 to 15.

1. Update the helm-release
   Update to the new major-version-image, set `primary.containerSecurityContext.runAsUser=0` and `diagnosticMode.enabled=true`.
2. Once the pod has restarted, exec into it, ensure the new version is active `postgres --version`.
3. `. /opt/bitnami/scripts/libos.sh`
4. `ensure_group_exists postgres -i 1001`
5. `ensure_user_exists postgres -i 1001 -g postgres`
6. `mv /bitnami/postgresql/data /bitnami/postgresql/olddata`
7. `mkdir -p /bitnami/postgresql/data; mkdir -p /bitnami/postgresql/oldbin`
8. `chown -R postgres:postgres /bitnami/postgresql/data /bitnami/postgresql/olddata`
9. `cd /tmp/`
10. Download the application-package from the *previous* release you upgraded from, check upstream Dockerfile.
`curl --remote-name https://downloads.bitnami.com/files/stacksmith/postgresql-14.5.0-17-linux-${OS_ARCH}-debian-11.tar.gz`
11. `cd /bitnami/postgresql/oldbin`
12. `tar --extract --directory . --file /tmp/postgresql-14.5.0-17-linux-amd64-debian-11.tar.gz`
13. `mv postgresql-14.5.0-linux-amd64-debian-11/files/postgresql/bin/* .`
14. `gosu postgres initdb -E UTF8 -D /bitnami/postgresql/data -U postgres`
15. `gosu postgres pg_upgrade -b /bitnami/postgresql/oldbin -B /opt/bitnami/postgresql/bin -d /bitnami/postgresql/olddata -D /bitnami/postgresql/data --socketdir=/tmp`
16. `./delete_old_cluster.sh`


If something borks, this is something to help you with:
1. `The source cluster was not shut down cleanly.`
2. Start a "old" server, you might have to create some config-files:
   `/bitnami/postgresql/oldbin/pg_ctl start -w -D /bitnami/postgresql/olddata/`
3. After successfull start, stop it: `/bitnami/postgresql/oldbin/pg_ctl stop -w -D /bitnami/postgresql/olddata/`
4. Try `pg_upgrade` again.