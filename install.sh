#!/usr/bin/env bash

# Install GitLab Runner, Docker, and Docker Machine on Ubuntu.

set -o errexit
set -o nounset
set -o pipefail

sudo apt-get --yes update
sudo apt-get --yes install \
  apt-transport-https \
  awscli \
  ca-certificates \
  curl \
  software-properties-common
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get --yes install gitlab-runner
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt-get --yes install docker-ce
base=https://github.com/docker/machine/releases/download/v0.16.0
curl -L ${base}/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine
sudo install /tmp/docker-machine /usr/local/bin/docker-machine

gitlab-runner --version
docker --version
docker-machine --version
