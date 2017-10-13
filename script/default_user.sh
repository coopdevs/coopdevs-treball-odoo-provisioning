#!/bin/bash
# To use a custom SSH key path set an environment variable called SSH_PATH

# Check if exist SSH_PATH env var
[[ -z "${SSH_PATH}" ]] && ssh_path=~/.ssh/id_rsa.pub || ssh_path="${SSH_PATH}"
echo "SSH key path: ${ssh_path}"
# Read SSH key and save it in var
read ssh_key < "$ssh_path"
ssh root@"$1" "bash -s" < ./script/create_user.sh "\"${ssh_key}\""
echo "Created user 'odoo' and copy the SSH key"
