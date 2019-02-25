# http://clarkgrubb.com/makefile-style-guide
# MAKEFLAGS += --warn-undefined-variables
SHELL := bash
# .SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# Platform-specific variables
# ---------------------------
PLATFORM_INFO:= $(shell python -m platform)
ifeq ($(findstring centos,$(PLATFORM_INFO)),centos)
	PLATFORM:= centos
endif
ifeq ($(findstring Ubuntu,$(PLATFORM_INFO)),Ubuntu)
	PLATFORM:= ubuntu
endif
ifeq ($(findstring Darwin,$(PLATFORM_INFO)),Darwin)
	PLATFORM:= darwin
	SET_VAGRANT_VERSION:= 1.8.5
	SET_VIRTUALBOX_VERSION:= 5.1.4
	SET_HOMEBREW_VERSION:= 1.0.4
endif

# PHONY (non-file) Targets
# ------------------------
.PHONY: all docker app sidekiq bundle

.DEFAULT_GOAL: all

# Common targets
# --------------

# Build dependencies
# ------------------
#  This target can be used to prepare a build system for the tasks in
#  this Makefile. You will need root privilges to do this.
#  `sudo make build-deps`

MY_VAGRANT_VERSION:= $(shell vagrant -v | head -n 1 | awk '{print $$NF}')
MY_VIRTUALBOX_VERSION:= $(shell vboxmanage --version)
MY_HOMEBREW_VERSION:=$(shell brew -v | head -n 1 | awk '{print $$NF}')

# https://stackoverflow.com/questions/3728372/version-number-comparison-inside-makefile/34527192
# RH_VER_MAJOR := $(shell echo $(RH_VER_NUM) | cut -f1 -d.)
# RH_VER_MINOR := $(shell echo $(RH_VER_NUM) | cut -f2 -d.)
# RH_GT_5_3 := $(shell [ $(RH_VER_MAJOR) -gt 5 -o \( $(RH_VER_MAJOR) -eq 5 -a $(RH_VER_MINOR) -ge 3 \) ] && echo true)
#
# ifeq ($(RH_GT_5_3),true)
# endif

# ifeq ($(shell test $(VER) -gt 4; echo $$?),0)

doctor:
ifeq ($(PLATFORM),centos)
	@echo "Building on CentOS is not yet supported."
endif
ifeq ($(PLATFORM),darwin)
	@echo ">>> Checking macOS dependencies <<<"
	@echo "Vagrant:" $(MY_VAGRANT_VERSION)
	@echo "Virtualbox:" $(MY_VIRTUALBOX_VERSION)
	@echo "Homebrew:" $(MY_HOMEBREW_VERSION)
endif
ifeq ($(PLATFORM),ubuntu)
	@echo "Building on Ubuntu is not yet supported."
endif

connect:
	eval $$(docker-machine env aws-lrnz)

ssh:
	docker-machine ssh aws-lrnz-test

DOCKER = app sidekiq postgres redis nginx elasticsearch

docker:
	@echo ">>> building docker images <<<"
	$(foreach docker,$(DOCKER),\
		(cd docker; \
		docker build --file Dockerfile.$(docker) . \
		  -t docker.lzops.io/lrnz/$(docker):0.0.1 \
		  -t docker.lzops.io/lrnz/$(docker):latest);)

push:
	@echo ">>> pushing docker images <<<"
	$(foreach docker,$(DOCKER),\
		(docker push \
		  docker.lzops.io/lrnz/$(docker):0.0.1; \
		docker push \
		  docker.lzops.io/lrnz/$(docker):latest);)

up: sync
	@echo ">>> starting <<<"
	docker run \
	  -p 80:80 \
	  -p 443:443 \
	  -p 8999:8999 \
	  -v /home/ubuntu/openresty-example:/app \
	  -v letsencrypt:/etc/resty-auto-ssl \
	  -v /home/ubuntu/openresty-example/self-signed:/etc/ssl/self-signed \
	  openresty-example \
	  -p /app \
	  -c nginx.conf

down:
	@echo ">>> stopping lrnz <<<"
	docker-compose down

sync:
	rsync -av \
	-e 'docker-machine ssh openresty-example' \
	--exclude='.git' \
	$$(pwd) :

#\
#--delete
