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

.DEFAULT_GOAL := up

export NAME := lemmy-meter
export ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export src.dir := $(ROOT)
export build.dir := $(ROOT)_build/
export DEPLOY_ROOT ?= $(build.dir)data/

####################################################################################################

include bmakelib/bmakelib.mk

.PHONY : $(ROOT)ansible/Makefile
include $(ROOT)ansible/Makefile

.PHONY : $(ROOT)mk/target-instances.mk
include $(ROOT)mk/target-instances.mk

.PHONY : $(ROOT)mk/vagrant.mk
include $(ROOT)mk/vagrant.mk

.PHONY : cluster/Makefile
include $(ROOT)cluster/Makefile

####################################################################################################

$(build.dir) :
	mkdir -p $(@)

####################################################################################################

$(DEPLOY_ROOT) : 	| $(build.dir)
	mkdir -p $(@)

####################################################################################################

TAGS : \
		$(src.dir)Makefile \
		$(src.dir)mk/*.mk
	universal-ctags -e -a -f $(ROOT)TAGS --language-force=make Makefile mk/*.mk


####################################################################################################

.PHONY : clean

clean :
	-rm -rf $(build.dir)

####################################################################################################

.PHONY : up

up : lemmy-meter.up

####################################################################################################

.PHONY : down

down : lemmy-meter.down

####################################################################################################

.PHONY : package

package : package.tar := $(build.dir)$(NAME).tar
package : clean cluster.deploy
	tar \
		-C $(DEPLOY_ROOT)$(NAME)/ \
		--create \
		--transform 's#^.#var#' \
		--file $(package.tar) \
		. \
	&& tar \
		-C $(ROOT) \
		--append \
		--file $(package.tar) \
		bin/lemmy-meter \
	&& gzip \
		--force \
		$(package.tar)

####################################################################################################

.PHONY : deploy

deploy : deploy-package := $(build.dir)$(NAME).tar.gz
deploy : $(ansible.playbook.deploy-remote)

####################################################################################################

.PHONY : reset-grafana-password

reset-grafana-password : $(ansible.playbook.reset-grafana-password)

####################################################################################################

.PHONY : deploy-vagrant

deploy-vagrant : export ANSIBLE_HOST_KEY_CHECKING=False
deploy-vagrant : ansible.lemmy-meter-password := lemmy-meter
deploy-vagrant : ansible.fqdn := test.lemmy-meter.info
deploy-vagrant : vagrant.up
deploy-vagrant : ansible.lemmy-meter-server := 192.168.33.10
deploy-vagrant : deploy
