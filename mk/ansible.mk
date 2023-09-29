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

ansible.root := $(ROOT)ansible/

####################################################################################################

ansible.playbook.deploy-remote := $(ansible.root)playbooks/deploy-remote.yml

####################################################################################################

$(ansible.playbook.deploy-remote) : bmakelib.default-if-blank( ansible.lemmy-meter-server,localhost )
$(ansible.playbook.deploy-remote) : bmakelib.default-if-blank( ansible.verbosity,-v )
$(ansible.playbook.deploy-remote) : $(lemmy-meter.archive)
	ansible-playbook \
		$(ansible.verbosity) \
		-i '$(ansible.lemmy-meter-server),' \
		-e 'ansible_user=lemmy-meter' \
		-e 'lemmy_meter_archive_path=$(<)' \
		-e 'lemmy_meter_server_app_root=/home/lemmy-meter/app' \
		-e 'lemmy_meter_server_deploy_root=/home/lemmy-meter/var' \
		$(@)
