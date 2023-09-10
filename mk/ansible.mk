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

####################################################################################################
# This Makefile contains all that is required to set up Ansible and required collections in a Python
# virtual env.
#
# 👉 The only target that you'd need to use this is `ansible`, as the others are supposed to be
#    private.
# 👉 The only variable that you'd need to use this is `ansible.venv.activate`.
####################################################################################################

####################################################################################################

.PHONY : ansible._ensure-global-variables

ansible._ensure-global-variables : bmakelib.error-if-blank( ROOT )
ansible._ensure-global-variables : bmakelib.error-if-blank( src.dir )
ansible._ensure-global-variables : bmakelib.error-if-blank( build.dir )

####################################################################################################

ansible.venv.dir := $(build.dir).venv/

####################################################################################################

define ansible.venv.activate
source $(ansible.venv.dir)bin/activate
endef

####################################################################################################

$(ansible.venv.dir) : $(build.dir)
$(ansible.venv.dir) :
	 [[ ! -d $(@) ]] && python3 -mvenv --prompt 'lemmy-clerk' $(@)

####################################################################################################

$(src.dir)requirements.txt : $(build.dir)
$(src.dir)requirements.txt :
	$(ansible.venv.activate) \
	&& pip install --upgrade -r $(@)

####################################################################################################

.PHONY : ansible.docker

ansible.install-docker-collection : $(src.dir)requirements.txt
ansible.install-docker-collection :
	$(ansible.venv.activate) \
	&& { ansible-galaxy collection list | grep community.docker; } \
	|| ansible-galaxy collection install community.docker

####################################################################################################

.PHONY : ansible

ansible : $(ansible.venv.dir)
ansible : $(src.dir)requirements.txt
ansible : ansible.install-docker-collection
