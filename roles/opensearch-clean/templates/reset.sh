#!/bin/bash

OC_USER="{{ opensearch_oc_user }}"
OC_PASS="{{ opensearch_oc_pass }}"

{% if opensearch_enable_security %}
USER_SLUG="-u $OC_USER:$OC_PASS"
OS_PROTO="https"
{% else %}
USER_SLUG=""
OS_PROTO="http"
{% endif %}

curl -s $USER_SLUG "$OS_PROTO://{{ inventory_hostname }}:9200/_cat/indices?v" | grep -o 'opencast_\w*' | while read line
do
  curl -s $USER_SLUG -X DELETE "$OS_PROTO://{{ inventory_hostname }}:9200/$line"
done
