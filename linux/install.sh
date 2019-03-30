#!/usr/bin/env bash

# Install GitLab Runner, Docker, and Docker Machine on Ubuntu.

set -o xtrace
set -o nounset
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# There seems to be no way to gracefully stop unattended upgrades, or to wait
# for them to finish, so we just try to disable them and kill them with fire.
# https://askubuntu.com/questions/15433/unable-to-lock-the-administration-directory-var-lib-dpkg-is-another-process/15469
# https://linuxconfig.org/disable-automatic-updates-on-ubuntu-18-04-bionic-beaver-linux

sudo systemctl stop apt-daily-upgrade.timer
sudo systemctl stop apt-daily.timer
sudo sed --in-place \
  --expression '/APT::Periodic::Update-Package-Lists/ s/1/0/' \
  --expression '/APT::Periodic::Unattended-Upgrade/ s/1/0/' \
  /etc/apt/apt.conf.d/20auto-upgrades

sudo killall apt.systemd.daily
sudo killall apt-get
sudo killall update-manager

while pid=$(sudo fuser /var/lib/apt/lists/lock 2>/dev/null); do
  tail --pid=${pid} --follow /dev/null 2>/dev/null
  sleep 2
done

set -o errexit

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

systemctl status gitlab-runner
gitlab-runner --version
sudo docker version
docker-machine version
