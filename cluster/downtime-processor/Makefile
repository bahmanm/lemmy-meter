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

####################################################################################################

.PHONY : cluster.downtime-processor.build
cluster.downtime-processor.build :
	docker build \
		--tag $(cluster)downtime-processor:$(cluster.tag) \
		--file Dockerfile \
		$(cluster.downtime-processor.srcdir)

####################################################################################################

$(cluster.deploy-root)downtime-processor: $(cluster.downtime-processor.srcdir)downtime-processor.pl
	mkdir $(@) \
	&& cp -r $(<) $(@)

####################################################################################################

.PHONY : cluster.downtime-processor.deploy

cluster.downtime-processor.deploy : $(cluster.deploy-root)downtime-processor
