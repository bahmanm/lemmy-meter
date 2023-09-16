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

SHELL := /usr/bin/env -S bash -o pipefail

.DEFAULT_GOAL := all

export NAME := lemmy-meter
export ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export src.dir := $(ROOT)
export build.dir := $(ROOT)_build/
export DEPLOY_ROOT ?= $(build.dir)data/

include bmakelib/bmakelib.mk
include mk/lemmy-docker.mk
include mk/lemmy-meter.mk

####################################################################################################

.PHONY : yq

yq :
	$$(hash yq 2>/dev/null)  \
	|| { echo "Cannot find 'yq'.  Perhaps the package is not installed?"; \
		false; }

####################################################################################################

$(build.dir) :
	mkdir -p $(@)

####################################################################################################

$(DEPLOY_ROOT) : | $(build.dir)
	mkdir -p $(@)

####################################################################################################

.PHONY : clean

clean :
	-sudo rm -rf $(build.dir)

####################################################################################################

.PHONY : all

all : lemmy-docker.prepare


####################################################################################################

.PHONY : TAGS

TAGS :
	universal-ctags -e -a -f $(ROOT)TAGS --language-force=make Makefile mk/*.mk
