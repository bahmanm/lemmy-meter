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

cluster.config.srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

####################################################################################################

.PHONY : cluster.config.build

cluster.config.build : ;

####################################################################################################

.PHONY : cluster.config.push

cluster.config.push : ;

####################################################################################################

$(cluster.deploy-root)config: $(wildcard $(cluster.config.srcdir)*.conf)
	mkdir -p $(@) \
	&& cp -r $(^) $(@)

####################################################################################################

.PHONY : cluster.config.deploy

cluster.config.deploy : $(cluster.deploy-root)config
