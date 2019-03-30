#!/usr/bin/env bash

# Pretty-print tags for the AMI.
tags='Key=type,Value=gitlab-runner'
tags+=' Key=platform,Value=linux'
tags+=" Key=version,Value=${TAG_VERSION}"
tags+=" Key=build,Value=${TAG_BUILD}"
tags+=" Key=gitlab-runner,Value=$(
  gitlab-runner --version | awk 'NR==1 { print $2 }'
)"
tags+=" Key=docker,Value=$(
  docker --version \
    | sed --quiet --regexp-extended \
    's/Docker version ([^,]+), build (\S+)/\1+\2/p'
)"
tags+=" Key=docker-machine,Value=$(
  docker-machine --version \
    | sed --quiet --regexp-extended \
    's/docker-machine version ([^,]+), build (\S+)/\1+\2/p'
)"

echo aws ec2 create-tags --tags ${tags} --resources
