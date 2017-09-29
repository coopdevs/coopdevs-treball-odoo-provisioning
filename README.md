# Ansible scripts to provision and deploy Odoo

These are [Ansible](http://docs.ansible.com/ansible/) playbooks (scripts) for managing an [Odoo](https://github.com/odoo/odoo) server.

#### Using LXC

You can create a local container instance with LXC using the `lxc/lxc-create.sh` script.
Run:

`./lxc/lxc-create.sh -n odoo-dev -t ubuntu -r xenial -h local.ofn.org`

## Expected state

To execute the first playbook `sysadmins.yml` to create the default user and the sysadmins users is needed that SSH root login has allowed without password. If you have the password os your root user, you can run `ssh-copy-id root@YOUR_HOST` like:

` user@local.odoo.org`

First state:
- Permit Root SSH login (modify `/etc/ssh/sshd_config`)
- Access without password (copy your SSH key)

## First step: Bash script to create default_user

Run `./script/default_user.sh`

This script creates the `odoo` user to execute the first playbook `sysadmin.yml`

## Playbooks

### Sysadmins
`sysadmins.yml` - Create default user `odoo` and sysadmins defined in your `inventory/host_vars/YOUR_HOST/conf.yml` in a dict called `sysadmins`.
The structure to declare user is:

```ỲAML
sysadmins:
  myname:
    key: "{{ lookup('env', 'HOME' ) }}/.ssh/id_rsa.pub"
    state: present
  user1:
    key: ../pub_keys/user1.pub
    state: present
```

Use `state: absent` to remove a user.

After execute this playbook the `odoo` the authorized SSH keys was removed and to acces it you can access with your sysadmin user and execute `sudo su odoo`.
All other users need acces to odoo group to manage the system service.

- Create default_user
- Create all sysadmin
- Add ssh keys
- Add sudo permisses

### Provision
`provision.yml` - Install and configure all required software on the server.

- Install common packages
- Install PostgreSQL database and create a user
- Install NodeJS and LESS

### Deploy
`deploy.yml` - Deploy source code from Odoo Nightly and install Python requirements.

- Install and create VirtualEnv
- Ansistrano deploy:
  - Download the source code
  - Before link task: Build
  - Before link task: Install requirements.txt
- Add systemd service

### Deploy Custom Modules
`deploy_custom_modules.yml` - Deploy the custom or thirdy part modules that you need.

You can make a repository with submodules pointing your module repository. [Like in this example](https://github.com/danypr92/odoo-organization-custom-modules)

Put custom modules repository url in your inventory/host_vars/your_host/config.yml file:

```YAML
custom_modules_repo: https://github.com/danypr92/odoo-organization-custom-modules.git
custom:modules_repo_branch: master
```

- Ansistrano git deploy.
- Update odoo.service to add addons.

### All
`all.yml` - Include all other playbooks
## Requirements

You will need Ansible on your machine to run the playbooks.
These playbooks will install the PostgreSQL database and Python virtualenv to manage python packages. 

It has currently been tested on **Ubuntu 16.04 Xenial (64 bit)**.

If you like run the `lxc-create` script, you need install [LXC](https://linuxcontainers.org/).

## Development - Using LXC containers

You can need a local container to test your customizations.
`lxc/lxc-create.sh` script creates a container, gets IP address of the new container and creates a known host whit this IP address.

`./lxc/lxc-create.sh -n NAME -t TEMPLATE -r RELEASE -h HOST`

Arguments:

```
  -n --name: LXC container name. Ex.: my-cont"
  -t --template: LXC container template. Ex.: ubuntu"
  -r --release: LXC container release. Ex.: xenial"
  -h --host: LXC container host name. Ex.: local.lxc.org"
```


**Name and host are required.** Default template is Ubuntu and default release is Xenial (16.04 LTS)
