# upgrade

kubectl -n nextcloud exec -it deploy/nextcloud -c nextcloud -- su www-data -s /bin/bash -c '/var/www/html/occ upgrade'

# maintenance-mode

kubectl -n nextcloud exec -it deploy/nextcloud -c nextcloud -- su www-data -s /bin/bash -c '/var/www/html/occ maintenance:mode --off'

# upgrade apps

kubectl -n nextcloud exec -it deploy/nextcloud -c nextcloud -- su www-data -s /bin/bash -c '/var/www/html/occ app:update --all'
