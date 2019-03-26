#!/usr/bin/env bash

# Pretty-print version strings for the bastion AMI description.
echo -n 'gitlab-runner '
gitlab-runner --version | head -1
docker --version
docker-machine --version
