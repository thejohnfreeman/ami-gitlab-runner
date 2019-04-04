# ami-gitlab-runner

To run an [autoscaling GitLab Runner with Docker Machine on
AWS](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws),
you must first [install a few
dependencies](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/#prepare-the-bastion-instance):

- [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository)
- [Docker Machine](https://docs.docker.com/machine/install-machine/#install-machine-directly)
- [GitLab Runner](https://docs.gitlab.com/runner/install/linux-repository.html)

This project exists to provide a set of Amazon Machine Images (AMIs), one for
each (region, platform) combination, which already have these dependencies
installed. Then creating a bastion is as simple launching an instance with the
right image.

Once you register a GitLab Runner with the `docker+machine` executor, it will
need an AMI for the instances that Docker Machine launches. The
[default](https://docs.docker.com/machine/drivers/aws/#default-amis) is Ubuntu
16.04. Docker Machine will install Docker on those instances after they
launch, [unless they already have Docker
installed](https://docs.docker.com/machine/reference/provision/), in which
case you'll save some time. Thus, it makes sense to use these one of these
images for the
[`amazonec2-ami`](https://docs.docker.com/machine/drivers/aws/#options) option
in your GitLab Runner's
[`MachineOptions`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersmachine-section)
(corresponding to the `amazonec2-region` you choose).

| Region | Platform | AMI |
|--------|----------|-----|
| `us-east-2` | Linux | `ami-0b316c366679a59d7` |

```shell
$ aws ec2 describe-images --image-ids ami-0b316c366679a59d7
```


## Architecture

Each directory, [`linux`](./linux) and [`windows`](./windows), has
a [Packer](https://www.packer.io/) template for that platform and a Makefile
for building the image. Each pulls a version number from the
[`version` file](./version) in this directory.


## TODO

- Build AMIs for more regions.
- Build and publish AMIs within a continuous deployment pipeline.
