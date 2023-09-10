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
include mk/ansible.mk

####################################################################################################

$(build.dir) :
	mkdir -p $(@)

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
