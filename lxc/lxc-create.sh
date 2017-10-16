#!/bin/bash


# Flags
# set -e

# Default values
TEMPLATE=ubuntu
RELEASE=xenial

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
  -n|--name)
  NAME="$2"
  shift # past argument
  ;;
  -t|--template)
  TEMPLATE="$2"
  shift # past argument
  ;;
  -r|--release)
  RELEASE="$2"
  shift # past argument
  ;;
  -h|--host)
  HOST="$2"
  shift
  ;;
esac
shift # past argument or value
done

if [ -z $NAME ] || [ -z $HOST ]
then
  echo "./lxc-create.sh -n NAME -t TEMPLATE -r RELEASE -h HOST"
  echo "Name and Host arguments are required!!"
  echo
  echo "Name: LXC container name. Ex.: my-cont"
  echo "Template: LXC container template. Ex.: ubuntu"
  echo "Release: LXC container release. Ex.: xenial"
  echo "Host: LXC container host name. Ex.: local.lxc.org"
  exit 0
fi

echo "Creating config file"
network_link="$(brctl show | awk '{if ($1 != "bridge")  print $1 }')"
cat >/tmp/lxc.conf <<EOL
  # Network configuration
  lxc.network.type = veth
  lxc.network.flags = up
  lxc.network.link = $network_link
EOL

# Check container
exist_container="$(sudo lxc-ls $NAME)"
echo "Check container ${exist_container}"
if [ -z "${exist_container}" ] ; then
  echo "Creating container $NAME"
  sudo lxc-create --name "$NAME" -f /tmp/lxc.conf -t "$TEMPLATE"  -- --release "$RELEASE"
fi
echo "Container ready"

# Check if is running container, if not start
count="0"
while [ "$count" -lt 5 ] && [ -z "$is_running" ]; do
  is_running=$(sudo lxc-ls --running -f | grep $NAME)
  if [ -z "$is_running" ] ; then
    echo "Starting container"
    sudo lxc-start -n "$NAME"
    ((count++))
  fi
done

# If not is running stop execution
if [ -z "$is_running" ]; then
  echo "Container not started..."
  echo "STOP EXECUTION"
  exit 0
fi

echo "Container is running..."
# Wait to start container and check the ip
count="0"
ip_container="$( sudo lxc-info -n "$NAME" -iH )"
while [ "$count" -lt 5 ] && [ -z "$ip_container" ] ; do
  sleep 2
  echo "waiting container ip..."
  ip_container="$( sudo lxc-info -n "$NAME" -iH )"
  ((count++))
done
echo "Container IP: $ip_container"
echo

# ADD IP TO HOSTS
echo "Remove old host $HOST form /etc/hosts"
sudo sed -i '/'$HOST'/d' /etc/hosts
host_entry="$ip_container       $HOST"
echo "Add '$host_entry' to /etc/hosts"
sudo -- sh -c "echo $host_entry >> /etc/hosts"
echo
# SSH Key
echo "Remove old $HOST of ~/.ssh/know_hosts"
ssh-keygen -R $HOST
echo
echo "$(sudo lxc-ls -f $NAME)"
echo


# Install python2.7 in container:
echo "Installing Python2.7"
sudo lxc-attach -n "$NAME" -- sudo apt update
sudo lxc-attach -n "$NAME" -- sudo apt install -y python2.7

# Allow SSH ROOT access
sudo lxc-attach -n "$NAME" -- /bin/sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo lxc-attach -n "$NAME" -- /bin/sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

sudo lxc-attach -n "$NAME" -- passwd root <<EOL
root
root
EOL

sudo lxc-attach -n "$NAME" -- userdel ubuntu
sudo lxc-stop -n "$NAME"
sudo lxc-start -n "$NAME"
# Copy ssh key
[[ -z "${SSH_PATH}" ]] && ssh_path=~/.ssh/id_rsa.pub || ssh_path="${SSH_PATH}"
read ssh_key < "${ssh_path}"
sudo lxc-attach -n "$NAME" -- bash -c "mkdir /root/.ssh/ && echo '$ssh_key' > /root/.ssh/authorized_keys"

echo -e "\n\nNow you can access runing:\n\n\t'ssh root@$HOST'\n"
