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

cluster.alertmanager.srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

####################################################################################################

.PHONY : cluster.alertmanager.build

cluster.alertmanager.build : ;

####################################################################################################

.PHONY : cluster.alertmanager.push

cluster.alertmanager.push : ;

####################################################################################################

$(cluster.deploy-root)alertmanager: $(cluster.alertmanager.srcdir)alertmanager
	cp -r $(^) $(@)

####################################################################################################

.PHONY : cluster.alertmanager.deploy

cluster.alertmanager.deploy : $(cluster.deploy-root)alertmanager
