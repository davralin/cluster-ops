#!/bin/bash
gpg --encrypt-files -r "B4AD172960C32F5FCEE8B6C8D91FA122CA59FD47" --batch --yes *.yaml
gpg --encrypt-files -r "B4AD172960C32F5FCEE8B6C8D91FA122CA59FD47" --batch --yes *config
