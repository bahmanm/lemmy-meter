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

cluster.downtime-processor.srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
cluster.downtime-processor.tag := $(cluster.prefix)downtime-processor:$(cluster.tag)
cluster.downtime-processor.sources := $(cluster.downtime-processor.srcdir)downtime-processor.pl
cluster.downtime-processor.files := \
	downtime-processor.pl \
	scheduled-downtime-schema.json \
	scrape-targets.txt

####################################################################################################

$(cluster.downtime-processor.srcdir)downtime-processor.pl :
	perl -cW $(@)

####################################################################################################

.PHONY : cluster.downtime-processor.build

cluster.downtime-processor.build : $(cluster.downtime-processor.sources)
	cd $(cluster.downtime-processor.srcdir) \
	&& docker build \
		--tag $(cluster.downtime-processor.tag) \
		--file Dockerfile \
		$(cluster.downtime-processor.srcdir) \
	&& yq \
		-i \
		'.services.downtime-processor.image = "$(cluster.downtime-processor.tag)"' \
		$(cluster.srcdir)docker-compose.yml

####################################################################################################

.PHONY : cluster.downtime-processor.push

cluster.downtime-processor.push :
	docker push $(cluster.downtime-processor.tag)

####################################################################################################

$(cluster.deploy-root)downtime-processor: $(cluster.downtime-processor.files:%=$(cluster.downtime-processor.srcdir)%)
	mkdir -p $(@) \
	&& cp -r $(^) $(@)

####################################################################################################

.PHONY : cluster.downtime-processor.deploy

cluster.downtime-processor.deploy : $(cluster.deploy-root)downtime-processor
