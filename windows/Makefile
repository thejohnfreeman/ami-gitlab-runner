# Use a Makefile to make it easier to resume after fixing errors.

.PHONY : build describe ssh test

version ?= $(shell cat ../version)
build ?= $(shell git log -1 --pretty=%h)

build :
	packer build -var version=${version} -var build=${build} packer.json

platform ?= windows
# Windows Server 2019 with Docker and SSH
image_id ?= ami-03247dd53ecd53cba
ssh_user ?= Administrator

describe :
	aws ec2 describe-images \
  --image-ids ${image_id} \
  --query 'Images[0].Name' \
  --output text

id :
	echo ami-gitlab-runner-${platform}-${version}-${build} > id

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
		--image-id ${image_id} \
		--instance-type t2.micro \
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

# The grep is to remove blank lines.
password : instance
	while true; do \
		aws ec2 get-password-data \
			--instance-id ${instance_id} \
			--priv-launch-key key \
			--query 'PasswordData' \
			--output text \
			| grep '\S' \
			| tee $@.tmp; \
		if [ -n "$$(cat $@.tmp)" ]; then \
			mv $@.tmp $@; \
			break; \
		else \
			rm $@.tmp; \
			sleep 1; \
		fi \
	done

ssh : address key running password
	ssh \
		-o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
		-o PasswordAuthentication=no \
		-i key \
		${ssh_user}@${address}

test : ssh

clean :
	-aws ec2 terminate-instances --instance-ids ${instance_id}
	-aws ec2 delete-key-pair --key-name ${id}-key
	rm -f stopped description installation running address instance key id password
	@# Leave behind the image ID.

# Clear the default goal as the last step, otherwise it will be set to the
# next target declared. With no default goal, users are forced to choose
# between build and test.
.DEFAULT_GOAL :=
