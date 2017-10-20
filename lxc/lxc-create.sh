#!/bin/bash


# Flags
# set -e

function check_error () {
  if [ $? -ne 0 ]; then
    echo -e "\n\n\t\tERROR!\n\nLog:\n"
    echo "$(cat $logfile)"
    exit 0
  fi
}

# Default values
TEMPLATE=ubuntu
RELEASE=xenial
logfile=/tmp/create-lxc.log

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
  -l|--logfile)
  logfile="$2"
  shift
  ;;
esac
shift # past argument or value
done

# Clear log file
> "$logfile"

if [ -z $NAME ] || [ -z $HOST ]
then
  echo "./lxc-create.sh -n NAME -t TEMPLATE -r RELEASE -h HOST -l LOGFILE_PATH"
  echo "Name and Host arguments are required!!"
  echo
  echo "Name: LXC container name. Ex.: my-cont"
  echo "Template: LXC container template. Ex.: ubuntu"
  echo "Release: LXC container release. Ex.: xenial"
  echo "Host: LXC container host name. Ex.: local.lxc.org"
  exit 0
fi

echo "Creating config file"
network_link="lxcbr0"
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
  sudo lxc-create --name "$NAME" -f /tmp/lxc.conf -t "$TEMPLATE"  -- --release "$RELEASE" &> "$logfile"
fi
check_error

echo "Container ready"

# Check if is running container, if not start
count="0"
while [ "$count" -lt 5 ] && [ -z "$is_running" ]; do
  is_running=$(sudo lxc-ls --running -f | grep $NAME)
  if [ -z "$is_running" ] ; then
    echo "Starting container"
    sudo lxc-start -n "$NAME" &>> "$logfile"
    ((count++))
  fi
done
check_error
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

# ADD IP TO HOSTS
echo "Remove old host $HOST form /etc/hosts"
sudo sed -i '/'$HOST'/d' /etc/hosts
host_entry="$ip_container       $HOST"
echo "Add '$host_entry' to /etc/hosts"
sudo -- sh -c "echo $host_entry >> /etc/hosts"
# SSH Key
echo "Remove old host $HOST of ~/.ssh/know_hosts"
ssh-keygen -R "$HOST" &>> "$logfile"
check_error
# Install python2.7 in container:
echo "Installing Python2.7"
sudo lxc-attach -n "$NAME" -- sudo apt update &>> "$logfile"
check_error
sudo lxc-attach -n "$NAME" -- sudo apt install -y python2.7 &>> "$logfile"
check_error
# Allow SSH ROOT access
sudo lxc-attach -n "$NAME" -- /bin/sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo lxc-attach -n "$NAME" -- /bin/sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

sudo lxc-attach -n "$NAME" -- userdel ubuntu &>> "$logfile"
check_error
sudo lxc-attach -n "$NAME" -- rm -r /home/ubuntu &>> "$logfile"
check_error
echo
echo "$(sudo lxc-ls -f $NAME)"

sudo lxc-stop -n "$NAME" &>> "$logfile"
check_error
sudo lxc-start -n "$NAME" &>> "$logfile"
check_error
# Copy ssh key
[[ -z "${SSH_PATH}" ]] && ssh_path=~/.ssh/id_rsa.pub || ssh_path="${SSH_PATH}"
read ssh_key < "${ssh_path}" &>> "$logfile"
sudo lxc-attach -n "$NAME" -- bash -c "mkdir /root/.ssh/ && echo '$ssh_key' > /root/.ssh/authorized_keys" &>> "$logfile"
check_error
echo -e "\n\nNow you can access runing:\n\n\t'ssh root@$HOST'\n"
echo "You can view to the log in: $logfile"
