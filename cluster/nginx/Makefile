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

cluster.nginx.srcdir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

####################################################################################################

.PHONY : cluster.nginx.build

cluster.nginx.build : ;

####################################################################################################

.PHONY : cluster.nginx.push

cluster.nginx.push : ;

####################################################################################################

$(cluster.deploy-root)nginx: $(cluster.nginx.srcdir)nginx
	cp -r $(<) $(@)

####################################################################################################

.PHONY : cluster.nginx.deploy

cluster.nginx.deploy : $(cluster.deploy-root)nginx
