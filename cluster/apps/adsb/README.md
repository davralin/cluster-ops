I had serious issues using LAT, LONG, and ALT-values from global secrets.

They seem to be converted to int, rather than staying as string.

From lack of time, I ended up re-writing the manifests to use a manually created secret instead.
That secret is created using:
kubectl create secret generic adsb-lat-long-alt -n adsb --from-literal='lat=XXX' --from-literal='long=XXX' --from-literal='alt=XXX' --from-literal='opensky-serial=XXX'
