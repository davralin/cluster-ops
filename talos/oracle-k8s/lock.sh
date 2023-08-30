#!/bin/bash
gpg --encrypt-files -r "0xD91FA122CA59FD47" --batch --yes *.yaml
gpg --encrypt-files -r "0xD91FA122CA59FD47" --batch --yes talosconfig
