#!/bin/bash

###################
# CONTAINER
###################

# Randomly assign tag ID
ob_id=$(shuf -i 10000-20000 -n 1)
sed -i 's/ob_id/'$ob_id'/g' /etc/monitrc

mkdir -p /ebs/logs/{monit,hhvm}
touch /ebs/logs/hhvm/hhvm.pid
touch /ebs/logs/hhvm/error.log
touch /ebs/logs/hhvm/access.log
#chown -R nginx:nginx /ebs/logs/hhvm

###################
# MONITOR
###################

# Set the monit lib directory
mkdir -p /var/lib/monit
# Set the proper monit config permissions
chmod 700 /etc/monitrc
# Link to the compiled applciation
ln /usr/local/bin/hhvm /usr/bin/hhvm
# We will let Monit take care of starting services
/usr/local/bin/monit -I -c /etc/monitrc -l /ebs/logs/monit/monit.log
