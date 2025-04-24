#!/bin/bash

# Get current tag
IMMICH_TAG=$(grep immich_version ansible/roles/immich_compose/defaults/main.yml | cut -f2 -d' ')
echo $IMMICH_TAG

# Get set tag
HELM_TAG=$(grep tag kubernetes/apps/nextcloud/immich/helm-release.yaml | cut -f2 -d':' | cut -f2 -d' ')
echo $HELM_TAG

# Update with new tag
sed 's/'$HELM_TAG'/'$IMMICH_TAG'/g' -i kubernetes/apps/nextcloud/immich/helm-release.yaml
