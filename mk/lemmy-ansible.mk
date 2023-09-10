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
# This Makefile contains all that is required to configure the playbook used to install Lemmy.
#
# It, essentially, grabs a copy of "lemmy-ansible" repo and sets the values of relevant variables
# use by the playbook.
#
# 👉 The only target that you'd need to use this is `lemmy-ansible`, as the others are supposed to
#    be private.
####################################################################################################

####################################################################################################

.PHONY : ensure-variables

ensure-variables : bmakelib.error-if-blank( ROOT )
ensure-variables : bmakelib.error-if-blank( src.dir )
ensure-variables : bmakelib.error-if-blank( build.dir )

####################################################################################################

.PHONY : openssl

openssl : bmakelib.default-if-blank( OPENSSL,openssl )
openssl :
	$$(hash $(OPENSSL) 2>/dev/null)  \
	|| { echo "Cannot find '$(OPENSSL)'.  Perhaps the package is not installed?"; \
		false; }

####################################################################################################

$(build.dir)lemmy-ansible : $(build.dir)
$(build.dir)lemmy-ansible :
	cd $(build.dir) \
	&& git clone git@github.com:LemmyNet/lemmy-ansible.git -b main

####################################################################################################

.PHONY : $(build.dir)lemmy-ansible.variables

lemmy-ansible.variables : openssl
lemmy-ansible.variables : $(build.dir)lemmy-ansible
lemmy-ansible.variables : _postgres_password = $(shell $(OPENSSL) rand -base64 15)
lemmy-ansible.variables : bmakelib.default-if-blank( lemmy.var.postgres_password,$(_postgres_password) )
lemmy-ansible.variables : bmakelib.default-if-blank( lemmy.var.domain,lemmy.lemmy-clerk.app )

####################################################################################################

.PHONY : $(build.dir)lemmy-ansible.prepare

lemmy-ansible.config-files : $(build.dir)lemmy-ansible
lemmy-ansible.config-files : lemmy-ansible.variables
lemmy-ansible.config-files : host_vars.dir = inventory/host_vars/$(lemmy.var.domain)/
lemmy-ansible.config-files : hosts.dir = inventory/
lemmy-ansible.config-files :
	cd $(build.dir)lemmy-ansible \
	&& { \
		mkdir -p $(host_vars.dir) \
		&& cp examples/config.hjson $(host_vars.dir); \
	} \
	&& { \
		mkdir -p $(host_vars.dir)passwords \
		&& echo '$(lemmy.var.postgres_passwrd)' > $(host_vars.dir)passwords/postgres}; \
	} \
	&& { \
		cp examples/hosts $(hosts.dir) \
		&& perl -pi -E 's/(.+domain=)([\w|\.]+)(.+)/$$1$(lemmy.var.domain)$$3/' $(hosts.dir)/hosts; \
	}

####################################################################################################

.PHONY : lemmy-ansible

lemmy-ansible : $(info Preparing lemmy-ansible playbook...)
lemmy-ansible : ensure-variables
lemmy-ansible : lemmy-ansible.config-files
