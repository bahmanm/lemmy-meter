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

####################################################################################################

.PHONY : vagrant.up

vagrant.up : bmakelib.error-if-blank( ansible.lemmy-meter-password )
vagrant.up : bmakelib.error-if-blank( ansible.fqdn )
vagrant.up : bmakelib.default-if-blank( ansible.ssh.authorized_key,~/.ssh/id_rsa.pub )
vagrant.up : bmakelib.default-if-blank( vagrant.options, )
	$(ansible.venv.activate) \
	&& export hashed_password=$$(python -c \
		"from passlib.hash import sha512_crypt; print(sha512_crypt.using(rounds=5000).hash('$(ansible.lemmy-meter-password)'))") \
	&& { \
		vagrant status lemmy_meter --machine-readable \
		| grep -q 'lemmy_meter,state,not_created'; \
	}  \
	|| true \
	&& { \
		export ANSIBLE_ARGS="-e setup_server_hashed_password='$${hashed_password}'" \
		&& ANSIBLE_ARGS+=" -e setup_server_ssh_public_key='$(ansible.ssh.authorized_key)'" \
		&& ANSIBLE_ARGS+=" -e setup_server_fqdn='$(ansible.fqdn)'" \
		&& vagrant up $(vagrant.options); \
	}

####################################################################################################

.PHONY : vagrant.desktroy

vagrant.desktroy : bmakelib.default-if-blank( vagrant.options,-f )
	vagrant destroy $(vagrant.options)
