In order to create the secret, you can't create it regularly with sops and a secret-file.

The regurlar way ends up with `Secret/ddns/docker-cloudflare-config conflict, error: data values must be of type string`.

A simple sops --encrypt of the config.yaml encrypts the values, but the structure isn't kept as it should.

Therefore, we encrypt the config-file as a config-yaml (which isn't a yaml-file due to missing .yaml-extension, and we magically fix it in the deployment instead.

