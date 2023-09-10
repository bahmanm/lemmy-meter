# -*- mode: ruby -*-
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

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"

  config.vm.define "lemmy" do |lemmy|
    lemmy.vm.box = "ubuntu/jammy64"
    lemmy.vm.hostname = "lemmy.lemmy-clerk.app"
    lemmy.vm.network "private_network", ip: "192.168.56.150"

    lemmy.vm.provision "ansible" do |ansible|
      ansible.verbose = "v"
      ansible.playbook = "lemmy-ansible/lemmy.yml"
    end
  end
end
