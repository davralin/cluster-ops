#!/bin/bash
talosctl gen secrets
talosctl gen config --with-secrets secrets.yaml \
  --with-examples=false --with-docs=false \
  --config-patch @all-patch.yaml --config-patch-control-plane @cp-patch.yaml \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.8.1 \
  HomeProd https://homeprod.internal:6443
#  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.8.1 \ # QEMU
#  --install-image factory.talos.dev/installer/4b3cd373a192c8469e859b7a0cfbed3ecc3577c4a2d346a37b0aeff9cd17cdb0:v1.8.1 \ # Intel