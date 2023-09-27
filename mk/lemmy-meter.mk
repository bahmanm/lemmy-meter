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

lemmy-meter..deploy-root = $(DEPLOY_ROOT)lemmy-meter/
lemmy-meter..src-docker-compose.yml := $(ROOT)docker/docker-compose.yml
lemmy-meter..docker-compose.yml = $(lemmy-meter..deploy-root)docker-compose.yml

lemmy-meter..ts = $(shell date '+%Y%m%d-%H%M%S')

lemmy-meter..grafana-volume := $(lemmy-meter..deploy-root)volumes/grafana
lemmy-meter..src-grafana.db := $(ROOT)config/grafana.db
lemmy-meter..grafana.db = $(lemmy-meter..deploy-root)volumes/grafana/grafana.db
lemmy-meter..grafana.db.backup = $(lemmy-meter..src-grafana.db).$(lemmy-meter..ts).backup

####################################################################################################

.PHONY : lemmy-meter..ensure-variables

lemmy-meter..ensure-variables : bmakelib.error-if-blank( build.dir )
lemmy-meter..ensure-variables : bmakelib.error-if-blank( NAME )
lemmy-meter..ensure-variables : bmakelib.error-if-blank( DEPLOY_ROOT )

####################################################################################################

$(lemmy-meter..deploy-root) :	| $(DEPLOY_ROOT)
	mkdir -p $(lemmy-meter..deploy-root)

####################################################################################################

$(lemmy-meter..grafana.db) :	$(lemmy-meter..src-grafana.db) \
		| $(lemmy-meter..grafana-volume)
	cp $(<) $(@)

####################################################################################################

.PHONY : lemmy-meter..volumes

lemmy-meter..volumes :	| $(lemmy-meter..deploy-root)
	cp \
		$(src.dir)config/blackbox_exporter-config.yml \
		$(src.dir)config/grafana-config.ini \
		$(lemmy-meter..deploy-root) \
	&& mkdir -p $(lemmy-meter..deploy-root)prometheus-config \
	&& cp -r \
		$(src.dir)config/prometheus/* \
		$(lemmy-meter..deploy-root)prometheus-config \
	&& mkdir -p $(lemmy-meter..deploy-root)volumes/prometheus \
	&& mkdir -p $(lemmy-meter..deploy-root)volumes/grafana \


####################################################################################################

$(lemmy-meter..docker-compose.yml) : $(lemmy-meter..src-docker-compose.yml) \
					| $(lemmy-meter..deploy-root)
	cp $(<) $(@)

####################################################################################################

.PHONY : lemmy-meter.up

lemmy-meter.up : lemmy-meter..ensure-variables \
		bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter ) \
		$(lemmy-meter..docker-compose.yml) \
		lemmy-meter..volumes \
		lemmy-meter.grafana-db.backup \
		$(lemmy-meter..grafana.db)
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

lemmy-meter.down : lemmy-meter..ensure-variables \
		bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter ) \
		| $(lemmy-meter..docker-compose.yml)
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

lemmy-meter.restart-% : lemmy-meter..ensure-variables \
		lemmy-meter..volumes \
		$(lemmy-meter..grafana.db) \
		$(lemmy-meter..docker-compose.yml) \
		bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter )
	export UID \
	&& export GID=$$(id -g) \
	&& docker compose \
		--ansi never \
		--file $(lemmy-meter..docker-compose.yml) \
		--project-name $(lemmy-meter.project-name) \
		--project-directory $(lemmy-meter..deploy-root) \
		restart \
		$(*)


####################################################################################################

.PHONY : lemmy-meter.grafana-db.backup

lemmy-meter.grafana-db.backup :		$(lemmy-meter..grafana.db.backup)

####################################################################################################

$(lemmy-meter..grafana.db.backup) : $(lemmy-meter..grafana.db)
	-cp $(<) $(@)


####################################################################################################

grafana..configure :	\
		bmakelib.default-if-blank( admin-password,admin ) \
		bmakelib.default-if-blank( lemmy-meter.project-name,lemmy-meter )
	export UID \
	&& export GID=$$(id -g) \
	&& cd $(lemmy-meter..deploy-root) \
	&& docker compose exec \
		--detach \
		grafana \
		grafana-cli \
			plugins \
			install \
			marcusolsson-csv-datasource
	&& docker compose exec \
		--detach \
		grafana \
		grafana-cli \
			--homepath '/var/lib/grafana' \
			admin \
			reset-admin-password \
			$(admin-password)
