build :
	packer build \
		-var version=$(shell cat ../version) \
		-var build=$(shell git log -1 --pretty=%h) \
		packer.json
