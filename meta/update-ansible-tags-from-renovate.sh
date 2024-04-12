#!/bin/bash

# Redis-stack in TubeArchivist
REDIS_STACK_TAG=$(grep tag cluster/apps/tubearchivist/helm-release-redis-stack.yaml | cut -f2 -d':' | sed 's/ //g')
echo $REDIS_STACK_TAG
ANSIBLE_REDIS_STACK_TAG=$(grep tubearchivist_compose_redis_version ansible/roles/tubearchivist-compose/defaults/main.yml | cut -f2 -d'"')
echo $ANSIBLE_REDIS_STACK_TAG
sed 's/'$ANSIBLE_REDIS_STACK_TAG'/'$REDIS_STACK_TAG'/g' -i ansible/roles/tubearchivist-compose/defaults/main.yml

# TubeArchivist
TUBEARCHIVIST_TAG=$(grep tag cluster/apps/tubearchivist/helm-release.yaml | cut -f2 -d':' | sed 's/ //g')
echo $TUBEARCHIVIST_TAG
ANSIBLE_TUBEARCHIVIST_TAG=$(grep tubearchivist_compose_version ansible/roles/tubearchivist-compose/defaults/main.yml | cut -f2 -d'"')
echo $ANSIBLE_TUBEARCHIVIST_TAG
#sed 's/'$ANSIBLE_TUBEARCHIVIST_TAG'/'$TUBEARCHIVIST_TAG'/g' -i ansible/roles/tubearchivist-compose/defaults/main.yml
