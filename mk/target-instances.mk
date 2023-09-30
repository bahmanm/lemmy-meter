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

target-instances..blackbox-probes := $(wildcard $(ROOT)config/prometheus/blackbox-probe.d/*.yml)

####################################################################################################

.PHONY : target-instances.add

target-instances.add : bmakelib.error-if-blank( instance )
target-instances.add : target-instances..add( $(target-instances..blackbox-probes) )


####################################################################################################

.PHONY : target-instances.add(%)

target-instances..add(%) :
	cp $(*) $(*).backup \
	&& yq -i '.[0].targets += "$(instance)"' $(*) \
	&& yq -i '.[0].targets = (.[0].targets | sort)' $(*)

####################################################################################################

.PHONY : target-instances.delete

target-instances.delete : bmakelib.error-if-blank( instance )
target-instances.delete : target-instances..delete( $(target-instances..blackbox-probes) )


####################################################################################################

.PHONY : target-instances.delete(%)

target-instances..delete(%) :
	cp $(*) $(*).backup \
	&& yq -i 'del(.[0].targets[] | select(. == "$(instance)"))' $(*)
