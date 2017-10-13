#!/bin/bash

# Create `odoo` user and copy the ssh key
useradd --create-home --shell /bin/bash odoo
su odoo -c "mkdir ~/.ssh/ && echo '$1' > /home/odoo/.ssh/authorized_keys"
echo "odoo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/1-odoo

# Close root SSH access and restart the service
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh
