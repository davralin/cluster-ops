certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/cloudflare.ini \
--dns-cloudflare-propagation-seconds 60 -d *.example.com \
--verbose --register-unsafely-without-email --agree-tos