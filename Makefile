####################################################################################################
# Copyright (c) 2023 Bahman Movaqar
#
# This file is part of lemmy-clerk.
# lemmy-clerk is free software: you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# lemmy-clerk is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with lemmy-clerk.
# If not, see <https://www.gnu.org/licenses/>.
####################################################################################################

SHELL := /usr/bin/env -S bash -o pipefail

.DEFAULT_GOAL := all

export ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export src.dir := $(ROOT)
export build.dir := $(ROOT)_build/

include bmakelib/bmakelib.mk
include mk/lemmy-ansible.mk

####################################################################################################

$(build.dir) :
	mkdir -p $(@)

####################################################################################################

venv.dir := $(build.dir).venv/

####################################################################################################

define venv.activate
source $(venv.dir)bin/activate
endef

####################################################################################################

$(venv.dir) : $(build.dir)
$(venv.dir) :
	 [[ ! -d $(@) ]] && python3 -mvenv --prompt 'lemmy-clerk' $(@)

####################################################################################################

$(src.dir)requirements.txt : $(build.dir)
$(src.dir)requirements.txt :
	cp $(@) $(<)

####################################################################################################

$(build.dir)requirements.txt : $(src.dir)requirements.txt
$(build.dir)requirements.txt : $(venv.dir)
$(build.dir)requirements.txt :
	$(venv.activate) \
	&& pip install --upgrade -r $(@)

####################################################################################################

.PHONY : ansible.docker

ansible.docker : $(build.dir)requirements.txt
ansible.docker :
	$(venv.activate) \
	&& { ansible-galaxy collection list | grep community.docker; } \
	|| ansible-galaxy collection install community.docker

####################################################################################################

vagrant.box.lemmy := lm

####################################################################################################

.PHONY : lemmy-up

lemmy-up :
	vagrant up $(vagrant.box.lemmy)

####################################################################################################

.PHONY : lemmy-suspend

lemmy-suspend :
	vagrant suspend $(vagrant.box.lemmy)

####################################################################################################

.PHONY : clean

clean :
	-rm -rf $(build.dir)
