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

lemmy-docker..checkout-dir := $(build.dir)lemmy-docker/
lemmy-docker..github-url := https://api.github.com/repos/LemmyNet/lemmy/releases/latest
lemmy-docker..tarball-url = $(shell curl --silent -XGET $(lemmy-docker..github-url) | jq -r '.tarball_url')
lemmy-docker..tag-name = $(shell curl --silent -XGET $(lemmy-docker..github-url) | jq -r '.tag_name')
lemmy-docker..deploy-root = $(DEPLOY_ROOT)lemmy/
lemmy-docker..original-docker-compose.yml := $(lemmy-docker..checkout-dir)docker-compose.yml
lemmy-docker..docker-compose.yml = $(lemmy-docker..deploy-root)docker-compose.yml

####################################################################################################

$(lemmy-docker..checkout-dir) : | $(build.dir)
$(lemmy-docker..checkout-dir) :
	curl \
		--location \
		--progress-bar \
		-H 'Accept: application/vnd.github+json' \
		-o - \
		$(lemmy-docker..tarball-url) \
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

$(lemmy-docker..docker-compose.yml) : | $(lemmy-docker..checkout-dir)
$(lemmy-docker..docker-compose.yml) : | $(lemmy-docker..deploy-root)
$(lemmy-docker..docker-compose.yml) : $(lemmy-docker..original-docker-compose.yml)
$(lemmy-docker..docker-compose.yml) : yq
$(lemmy-docker..docker-compose.yml) :
	cat $(<) \
	| yq 'del(.services.lemmy.build)' \
	| yq '. | (.services.lemmy.image = "dessalines/lemmy:$(lemmy-docker..tag-name)")' > \
		$(lemmy-docker..docker-compose.yml)

####################################################################################################


.PHONY : lemmy-docker..prepare

lemmy-docker..prepare : | $(lemmy-docker..checkout-dir)
lemmy-docker..prepare : $(lemmy-docker..docker-compose.yml)

####################################################################################################

$(lemmy-docker..deploy-root) : | $(lemmy-docker..checkout-dir)
$(lemmy-docker..deploy-root) : | $(DEPLOY_ROOT)
	mkdir -p $(@)

####################################################################################################

.PHONY : lemmy-docker..volumes

lemmy-docker..volumes : | $(lemmy-docker..deploy-root)
lemmy-docker..volumes :
	mkdir -p $(lemmy-docker..deploy-root)volumes/postgres \
	&& mkdir -p $(lemmy-docker..deploy-root)volumes/pictrs \
	&& sudo chown -R 991:991 $(lemmy-docker..deploy-root)volumes/pictrs \
	&& cp \
		$(lemmy-docker..checkout-dir)lemmy.hjson \
		$(lemmy-docker..checkout-dir)nginx.conf \
		$(lemmy-docker..deploy-root)

####################################################################################################

.PHONY : lemmy-docker.up

lemmy-docker.up : lemmy-docker..ensure-variables
lemmy-docker.up : bmakelib.default-if-blank( lemmy-docker.project-name,lemmy-docker )
lemmy-docker.up : lemmy-docker..prepare
lemmy-docker.up : lemmy-docker..volumes
lemmy-docker.up :
	docker-compose \
		--ansi never \
		--file $(lemmy-docker..docker-compose.yml) \
		--project-name $(lemmy-docker.project-name) \
		--project-directory $(lemmy-docker..deploy-root) \
		up \
		--detach \
		--remove-orphans \
		--wait \
		--wait-timeout 120

####################################################################################################

.PHONY : lemmy-docker.down

lemmy-docker.down : lemmy-docker..ensure-variables
lemmy-docker.down : bmakelib.default-if-blank( lemmy-docker.project-name,lemmy-docker )
lemmy-docker.down : | $(lemmy-docker..docker-compose.yml)
lemmy-docker.down :
	docker-compose \
		--ansi never \
		--file $(lemmy-docker..docker-compose.yml) \
		--project-name $(lemmy-docker.project-name) \
		down \
		--remove-orphans

####################################################################################################

.PHONY : lemmy-docker..ensure-variables

lemmy-docker..ensure-variables : bmakelib.error-if-blank( build.dir )
lemmy-docker..ensure-variables : bmakelib.error-if-blank( NAME )
lemmy-docker..ensure-variables : bmakelib.error-if-blank( DEPLOY_ROOT )
