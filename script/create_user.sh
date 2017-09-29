#!/bin/bash

# Create `odoo` user and copy the ssh key
useradd "odoo"
mkdir -p /home/odoo/.ssh/ && touch /home/odoo/.ssh/authorized_keys
echo "$1" > /home/odoo/.ssh/authorized_keys
chown -R odoo:odoo /home/odoo

touch /etc/sudoers.d/1-odoo
echo "odoo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/1-odoo

sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Need reboot to fix sshd_config changes.
# reboot ??
