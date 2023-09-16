####################################################################################################
# Copyright (c) 2023 Bahman Movaqar
#
# This file is part of lemmy-meter.
# lemmy-meter is free software: you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# lemmy-meter is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with lemmy-meter.
# If not, see <https://www.gnu.org/licenses/>.
####################################################################################################

SHELL := /usr/bin/env -S bash -o pipefail

.DEFAULT_GOAL := all

export NAME := lemmy-meter
export ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export src.dir := $(ROOT)
export build.dir := $(ROOT)_build/

include bmakelib/bmakelib.mk

####################################################################################################

.PHONY : yq

yq :
	$$(hash yq 2>/dev/null)  \
	|| { echo "Cannot find 'yq'.  Perhaps the package is not installed?"; \
		false; }

####################################################################################################

$(build.dir) :
	mkdir -p $(@)

####################################################################################################

lemmy-docker.dir := $(build.dir)lemmy-docker/
lemmy-docker.github-url := https://api.github.com/repos/LemmyNet/lemmy/releases/latest
lemmy-docker.original-docker-compose.yml := $(lemmy-docker.dir)docker-compose.yml
lemmy-docker.docker-compose.yml := $(lemmy-docker.dir)$(NAME)-docker-compose.yml

####################################################################################################

$(lemmy-docker.dir) : | $(build.dir)
$(lemmy-docker.dir) :
	curl \
		--location \
		--progress-bar \
		-H 'Accept: application/vnd.github+json' \
		-o - \
		$(lemmy-docker.tarball-url) \
	| tar \
		-C $(build.dir) \
		--wildcards \
		--strip-components=1 \
		--extract \
		--gzip \
		--file - \
		--transform='s/docker/lemmy-docker/' \
		LemmyNet-lemmy-*/docker

####################################################################################################

.PHONY : lemmy-docker.docker-compose

$(lemmy-docker.docker-compose.yml) : | $(lemmy-docker.dir)
$(lemmy-docker.docker-compose.yml) : $(lemmy-docker.original-docker-compose.yml)
$(lemmy-docker.docker-compose.yml) : yq
$(lemmy-docker.docker-compose.yml) :
	cat $(<) \
	| yq 'del(.services.lemmy.build)' \
	| yq '. | (.services.lemmy.image = "dessalines/lemmy:$(lemmy-docker.tag-name)")' > \
		$(lemmy-docker.docker-compose.yml)

####################################################################################################


.PHONY : lemmy-docker.prepare

lemmy-docker.prepare : lemmy-docker.tag-name := $(shell curl --silent -XGET $(lemmy-docker.github-url) | jq -r '.tag_name')
lemmy-docker.prepare : lemmy-docker.tarball-url := $(shell curl --silent -XGET $(lemmy-docker.github-url) | jq -r '.tarball_url')
lemmy-docker.prepare : | $(lemmy-docker.dir)
lemmy-docker.prepare : $(lemmy-docker.docker-compose.yml)

####################################################################################################

.PHONY : lemmy-docker.volumes

lemmy-docker.volumes : | $(lemmy-docker.dir)
	mkdir -p $(lemmy-docker.dir)volumes/pictrs \
	&& sudo chown -R 991:991 $(lemmy-docker.dir)volumes/pictrs

####################################################################################################

.PHONY : lemmy-docker.up

lemmy-docker.up : bmakelib.default-if-blank( lemmy-docker.project-name,lemmy-docker )
lemmy-docker.up : lemmy-docker.prepare
lemmy-docker.up : lemmy-docker.volumes
lemmy-docker.up :
	docker-compose \
		--ansi never \
		--file $(lemmy-docker.docker-compose.yml) \
		--project-name $(lemmy-docker.project-name) \
		up \
		--detach \
		--remove-orphans \
		--wait \
		--wait-timeout 120

####################################################################################################

.PHONY : lemmy-docker.down

lemmy-docker.down : bmakelib.default-if-blank( lemmy-docker.project-name,lemmy-docker )
lemmy-docker.down : lemmy-docker.prepare
lemmy-docker.down :
	docker-compose \
		--ansi never \
		--file $(lemmy-docker.docker-compose.yml) \
		--project-name $(lemmy-docker.project-name) \
		down \
		--remove-orphans

####################################################################################################

.PHONY : clean

clean :
	-sudo rm -rf $(build.dir)


####################################################################################################

.PHONY : all

all : lemmy-docker.prepare
