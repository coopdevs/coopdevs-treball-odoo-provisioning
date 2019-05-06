# Ansible inventories
This repository stores hosts informations and related variables for this specific instance of Odoo.

**WARNING**
_This repository is no longer mantained. We moved to [gitlab.com repository](https://gitlab.com/coopdevs/odoo-coopdevs-treball-provisioning)._

_In case you don't read this, an invalid version number is provided to make it crash with odoo-provisioning. If you want to use it no matter what, check out the previous commit or delete `odoo_provisioning_version` variable inside `inventory/group_vars/all.yml`._

## Requirements

1. Clone this repo and [odoo-provisioning](https://gitlab.com/femprocomuns/odoo-provisioning) in the same directory
2. Go to `odoo-provisioning` directory and install Ansible dependencies:
   ```
   ansible-galaxy -r requirements.yml
   ```
3. Run `ansible-playbook` command pointing to the `inventory/hosts` file of this repository:
   ```
   ansible-playbook playbooks/provision.yml -i ../odoo-coopdevs-treball-provisioning/inventory/hosts --ask-vault-pass --limit=dev
   ```
