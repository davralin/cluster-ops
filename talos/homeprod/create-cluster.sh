#!/bin/bash
talosctl gen secrets
talosctl gen config --with-secrets secrets.yaml \
  --with-examples=false --with-docs=false \
  --config-patch @all-patch.yaml --config-patch-control-plane @cp-patch.yaml \
  --install-image factory.talos.dev/installer/ee827ee541fb06e742e6d183f4e3c1a62a2d63d945cbbd0b1e76da9221af9d27:v1.12.4 \
  HomeProd https://homeprod.internal:6443
#  --install-image factory.talos.dev/installer/ee827ee541fb06e742e6d183f4e3c1a62a2d63d945cbbd0b1e76da9221af9d27:v1.12.4 \ # QEMU
#  --install-image factory.talos.dev/installer/ee827ee541fb06e742e6d183f4e3c1a62a2d63d945cbbd0b1e76da9221af9d27:v1.12.4 \ # Intel