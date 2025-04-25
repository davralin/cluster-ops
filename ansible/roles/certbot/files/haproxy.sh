#!/bin/bash
cd /etc/letsencrypt/live
for i in $(find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
	cat $i/fullchain.pem $i/privkey.pem > "/etc/haproxy/$i.pem"
done