#!/bin/sh

cfg_file=/etc/opencast/custom.properties
workflows_dir=/etc/opencast/workflows

node_hostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

# Set server urls to public DNS
if [ -e $cfg_file ] ; then
    tmp=$(mktemp)
    sed -e "s/^\(org\.opencastproject\.server\.url\=\).*/\1http:\/\/$node_hostname/g" \
        -e "s/^\(org\.opencastproject\.download\.url\=\).*/\1http:\/\/$node_hostname\/static/g" \
        $cfg_file > $tmp
    /bin/cp -f $tmp $cfg_file
fi

# Fix hardcoded External API publication url !
if [ -d $workflows_dir ] ; then
    for wf in $(grep -l "http://localhost:8080/api/events/" /etc/opencast/workflows/*) 
    do 
        tmp=$(mktemp)
        sed -e "s#http://localhost:8080/api/events/#http://$node_hostname/api/events/#g" \
            $wf > $tmp
        /bin/cp -f $tmp $wf
    done
fi
