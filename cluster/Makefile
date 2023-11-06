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

export cluster.srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export cluster.tag := $(shell git rev-parse --short HEAD)
export cluster.prefix := bahmanm/$(NAME).
export cluster.deploy-root := $(DEPLOY_ROOT)lemmy-meter/

####################################################################################################

cluster.components := \
	alertmanager \
	blackbox-exporter \
	config \
	downtime-processor \
	grafana \
	json-exporter \
	matrix-webhook \
	nginx \
	ntfy \
	prometheus

####################################################################################################

.PHONY : $(cluster.components:%=$(cluster.srcdir)%/Makefile)

include $(cluster.components:%=$(cluster.srcdir)%/Makefile)

####################################################################################################

define cluster.docker-compose
	export UID \
	&& export GID=$$(id -g) \
	&& export CLUSTER_DEPLOY_ROOT=$(cluster.deploy-root) \
	&& docker compose \
		--file $(cluster.deploy-root)docker-compose.yml \
		--project-name $(NAME) \
		--env-file $(cluster.deploy-root)config/$(cluster.env).conf
endef

####################################################################################################

$(cluster.deploy-root) :
	mkdir -p $(@)

####################################################################################################

$(cluster.deploy-root)docker-compose.yml : $(cluster.srcdir)docker-compose.yml
	cp $(<) $(@)

####################################################################################################

.PHONY : cluster.build

cluster.build : $(cluster.components:%=cluster.%.build)

####################################################################################################

.PHONY : cluster.push

cluster.push : $(cluster.components:%=cluster.%.push)

####################################################################################################

.PHONY : cluster.deploy

cluster.deploy : \
		cluster.ensure-variables \
		cluster.build \
		cluster.push
cluster.deploy : | $(cluster.deploy-root)
cluster.deploy : $(cluster.deploy-root)docker-compose.yml
cluster.deploy : $(cluster.components:%=cluster.%.deploy)

####################################################################################################

.PHONY : cluster.ensure-variables

cluster.ensure-variables : bmakelib.error-if-blank( cluster.env )

####################################################################################################

.PHONY : cluster.up

cluster.up : cluster.ensure-variables cluster.deploy
	$(cluster.docker-compose) \
		up \
		--force-recreate \
		--remove-orphans \
		--pull always \
		--detach

####################################################################################################

.PHONY : cluster.down

cluster.down : cluster.ensure-variables
	$(cluster.docker-compose) \
		down \
		--remove-orphans

####################################################################################################

.PHONY : cluster.restart

cluster.restart : cluster.ensure-variables
	$(cluster.docker-compose) \
		restart

####################################################################################################

cluster.restart(%) : cluster.restart
	$(cluster.docker-compose) \
		restart \
		$(*)
