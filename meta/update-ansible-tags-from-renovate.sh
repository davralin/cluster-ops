#!/bin/bash
# TubeArchivist
TUBEARCHIVIST_TAG=$(grep tag cluster/apps/tubearchivist/helm-release.yaml | cut -f2 -d':' | sed 's/ //g')
echo $TUBEARCHIVIST_TAG
ANSIBLE_TUBEARCHIVIST_TAG=$(grep tubearchivist_compose_version ansible/roles/tubearchivist-compose/defaults/main.yml | cut -f2 -d'"')
echo $ANSIBLE_TUBEARCHIVIST_TAG
sed 's/'$ANSIBLE_TUBEARCHIVIST_TAG'/'$TUBEARCHIVIST_TAG'/g' -i ansible/roles/tubearchivist-compose/defaults/main.yml
