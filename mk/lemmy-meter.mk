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

lemmy-meter..src-docker-compose.yml := $(ROOT)docker/docker-compose.yml
lemmy-meter..deploy-root = $(DEPLOY_ROOT)lemmy-meter/
lemmy-meter..docker-compose.yml = $(lemmy-meter..deploy-root)docker-compose.yml

####################################################################################################

.PHONY : lemmy-meter..ensure-variables

lemmy-meter..ensure-variables : bmakelib.error-if-blank( build.dir )
lemmy-meter..ensure-variables : bmakelib.error-if-blank( NAME )
lemmy-meter..ensure-variables : bmakelib.error-if-blank( DEPLOY_ROOT )

####################################################################################################

$(lemmy-meter..deploy-root) : | $(DEPLOY_ROOT)
$(lemmy-meter..deploy-root) :
	mkdir -p $(lemmy-meter..deploy-root)

####################################################################################################

.PHONY : lemmy-meter..volumes

lemmy-meter..volumes : | $(lemmy-meter..deploy-root)
	mkdir -p $(lemmy-meter..deploy-root)volumes/prometheus \
	mkdir -p $(lemmy-meter..deploy-root)volumes/grafana \
	&& cp \
		$(src.dir)config/blackbox_exporter-config.yml \
		$(src.dir)config/prometheus-config.yml \
		$(lemmy-meter..deploy-root)


####################################################################################################

$(lemmy-meter..docker-compose.yml) : $(lemmy-meter..src-docker-compose.yml)
$(lemmy-meter..docker-compose.yml) : | $(lemmy-meter..deploy-root)
$(lemmy-meter..docker-compose.yml) :
	cp $(<) $(@)

####################################################################################################

.PHONY : lemmy-meter.up

lemmy-meter.up : lemmy-meter..ensure-variables
lemmy-meter.up : bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter )
lemmy-meter.up : $(lemmy-meter..docker-compose.yml)
lemmy-meter.up : lemmy-meter..volumes
lemmy-meter.up :
	export UID \
	&& export GID=$$(id -g) \
	&& docker compose \
		--ansi never \
		--file $(lemmy-meter..docker-compose.yml) \
		--project-name $(lemmy-meter.project-name) \
		--project-directory $(lemmy-meter..deploy-root) \
		up \
		--detach \
		--remove-orphans \
		--wait \
		--wait-timeout 120

####################################################################################################

.PHONY : lemmy-meter.down

lemmy-meter.down : lemmy-meter..ensure-variables
lemmy-meter.down : bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter )
lemmy-meter.down : | $(lemmy-meter..docker-compose.yml)
lemmy-meter.down :
	export UID \
	&& export GID=$$(id -g) \
	&& docker compose \
		--ansi never \
		--file $(lemmy-meter..docker-compose.yml) \
		--project-name $(lemmy-meter.project-name) \
		--project-directory $(lemmy-meter..deploy-root) \
		down \
		--remove-orphans


####################################################################################################

.PHONY : lemmy-meter.restart-%

lemmy-meter.restart-% : lemmy-meter..ensure-variables
lemmy-meter.restart-% : lemmy-meter..volumes
lemmy-meter.restart-% : | $(lemmy-meter..docker-compose.yml)
lemmy-meter.restart-% : bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter )
	export UID \
	&& export GID=$$(id -g) \
	&& docker compose \
		--ansi never \
		--file $(lemmy-meter..docker-compose.yml) \
		--project-name $(lemmy-meter.project-name) \
		--project-directory $(lemmy-meter..deploy-root) \
		restart \
		$(*)
