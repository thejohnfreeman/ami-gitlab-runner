# Use a Makefile to make it easier to resume after fixing errors.

.PHONY : build test describe_base_image
.DEFAULT_GOAL := build

version ?= $(shell git log -1 --pretty=%h)

base_image_id ?= ami-f4f4cf91
mode ?= build

test : base_image_id ?= ${image}
test : mode := test

default_user ?= ubuntu

describe_base_image :
	aws ec2 describe-images \
  --image-ids ${base_image_id} \
  --query 'Images[0].Description' \
  --output text

id :
	echo bastion-${mode}-ami-${version} > id

# We deliberately use recursive expansion to read IDs from checkpoints.
id = $(shell cat id)

# We use this rule pattern to make sure the checkpoint file is not created
# unless the command exits successfully:
#
# target :
# 	command > $@.tmp
# 	mv $@.tmp $@

# Create the key pair.
key : id
	touch $@.tmp
	chmod 600 $@.tmp
	aws ec2 create-key-pair \
		--key-name ${id}-key \
		--query 'KeyMaterial' \
		--output text \
		> $@.tmp
	mv $@.tmp $@

instance : key
	aws ec2 run-instances \
		--count 1 \
		--instance-market-options '{"MarketType": "spot"}' \
		--image-id ${base_image_id} \
		--instance-type t2.micro \
		--security-groups gitlab-runners \
		--key-name ${id}-key \
		--query 'Instances[0].InstanceId' \
		--output text \
		| tee $@.tmp
	mv $@.tmp $@

instance_id = $(shell cat instance)

running : instance
	aws ec2 wait instance-running --instance-ids ${instance_id}
	touch $@

address : running
	aws ec2 describe-instances \
		--instance-ids ${instance_id} \
		--query 'Reservations[0].Instances[0].PublicDnsName' \
		--output text \
		| tee $@.tmp
	mv $@.tmp $@

address = $(shell cat address)

ssh := ssh \
  -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -i key

# This target is just for debugging.
ssh : address key running
	${ssh} ${default_user}@${address}

installation : address key running
	${ssh} ${default_user}@${address} <install.sh
	touch $@

description : installation address key running
	echo "GitLab Runner AMI ${version}" > $@.tmp
	echo "Base AMI: ${base_image_id}" >> $@.tmp
	${ssh} ${default_user}@${address} <versions.sh | tail -3 >>$@.tmp
	mv $@.tmp $@

stopped : instance description
	aws ec2 stop-instances --instance-ids ${instance_id}
	aws ec2 wait instance-stopped --instance-ids ${instance_id}
	touch $@

image : instance description stopped
	aws ec2 create-image \
		--name ami-gitlab-runner-${version} \
		--instance-id ${instance_id} \
		--description "$$(cat description)" \
		--query 'ImageId' \
		--output text \
		| tee $@.tmp
	mv $@.tmp $@

image = $(shell cat image)

build : describe_base_image image
	aws ec2 wait image-available --image-ids ${image}
	$(MAKE) clean

test : describe_base_image address key running
	${ssh} ${default_user}@${address} \
		'PS4="$ "; set -o xtrace; gitlab-runner --version; docker --version; docker-machine --version'
	$(MAKE) clean

clean :
	-aws ec2 terminate-instances --instance-ids ${instance_id}
	-aws ec2 delete-key-pair --key-name ${id}-key
	rm -f stopped description installation running address instance key id
	@# Leave behind the image ID.
