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

ansible.root := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ansible.venv := $(build.dir)ansible-venv/
ansible.requirements := $(ansible.root)requirements.txt
ansible.venv.activate := source $(ansible.venv)bin/activate

####################################################################################################

ansible.playbook.deploy-remote := $(ansible.root)playbooks/deploy-remote.yml
ansible.playbook.reset-grafana-password := $(ansible.root)playbooks/reset-grafana-password.yml
ansible.playbook.setup-server := $(ansible.root)playbooks/setup_server/setup_server.yml

####################################################################################################

$(ansible.venv) :
	python3 -mvenv --prompt 'ansible' $(@) \
	&& source $(@)bin/activate \
	&& pip install --upgrade pip \
	&& pip install -r $(ansible.requirements)

####################################################################################################

$(ansible.playbook.deploy-remote) : bmakelib.error-if-blank( ansible.lemmy-meter-server )
$(ansible.playbook.deploy-remote) : bmakelib.default-if-blank( ansible.app-root,/home/lemmy-meter/app )
$(ansible.playbook.deploy-remote) : bmakelib.default-if-blank( ansible.deploy-root,/home/lemmy-meter/var )
$(ansible.playbook.deploy-remote) : bmakelib.default-if-blank( ansible.verbosity,-v )
$(ansible.playbook.deploy-remote) : bmakelib.error-if-blank( deploy-package )
$(ansible.playbook.deploy-remote) : \
		| $(ansible.venv)
	$(ansible.venv.activate) \
	&& ansible-playbook \
		$(ansible.verbosity) \
		-i '$(ansible.lemmy-meter-server),' \
		-e 'ansible_user=lemmy-meter' \
		-e 'lemmy_meter_archive_path=$(deploy-package)' \
		$(@)

####################################################################################################

$(ansible.playbook.reset-grafana-password) : bmakelib.error-if-blank( ansible.grafana.new-password )
$(ansible.playbook.reset-grafana-password) : bmakelib.default-if-blank( ansible.verbosity,-v )
$(ansible.playbook.reset-grafana-password) : | $(ansible.venv)
	$(ansible.venv.activate) \
	&& ansible-playbook \
		$(ansible.verbosity) \
		-i '$(ansible.lemmy-meter-server),' \
		-e 'ansible_user=lemmy-meter' \
		-e 'lemmy_meter_server_app_root=/home/lemmy-meter/app' \
		-e 'lemmy_meter_server_deploy_root=/home/lemmy-meter/var' \
		-e 'lemmy_meter_grafana_new_password=$(ansible.grafana.new-password)' \
		$(@)

####################################################################################################

$(ansible.playbook.setup-server) : bmakelib.error-if-blank( ansible.lemmy-meter-server )
$(ansible.playbook.setup-server) : bmakelib.default-if-blank( ansible.verbosity,-v )
$(ansible.playbook.setup-server) : bmakelib.error-if-blank( ansible.user )
$(ansible.playbook.setup-server) : bmakelib.error-if-blank( ansible.lemmy-meter-password )
$(ansible.playbook.setup-server) : bmakelib.default-if-blank( ansible.ssh.authorized_key,~/.ssh/id_rsa.pub )
$(ansible.playbook.setup-server) : | $(ansible.venv)
	$(ansible.venv.activate) \
	&& hashed_password=$$(python -c \
		"from passlib.hash import sha512_crypt; print(sha512_crypt.using(rounds=5000).hash('$(ansible.lemmy-meter-password)'))") \
	ansible-playbook \
		$(ansible.verbosity) \
		-i '$(ansible.lemmy-meter-server),' \
		-e "setup_server_hashed_password=$${hashed_password}" \
		-e "setup_server_ssh_public_key=$$(<$(ansible.ssh.authorized_key))" \
		--become-user $(ansible.user) \
		--ask-pass \
		$(@)
