#!/bin/bash

set -e

#
# Variables
#
APP="swarm_core_audit.sh"

#
# Functions
#

is_missing() {
    if ! command -v $1 &> /dev/null ; then
        printf "${APP}: Command '$1' not found; Please ensure that '$1' is installed and exists in \$PATH.\n"
	    exit 1
    fi
}

#
# Begin script
#

# Check requirements
is_missing jq
is_missing curl

# check to see DOCKER_HOST is set & set curl command to be able to re-use it and help readability of the script
if [ -n "${UCP_URL}" ]
then
  CURL_CMD="curl -s -m 15 --cacert /data/ca.pem --key /data/key.pem --cert /data/cert.pem https://${UCP_URL}"

  # check to see if the UCP endpoint is available
  if [ "$(curl -s --cacert /data/ca.pem "https://${UCP_URL}/_ping")" != "OK" ]
  then
    # try without the cacert
    if [ "$(curl -s "https://${UCP_URL}/_ping")" != "OK" ]
    then
      echo "ERROR: UCP unavailable/unhealthy at https://${UCP_URL}/_ping"
      exit 1
    else
      # if this works, we need to not include the CA cert
      CURL_CMD="curl -s -m 15 --key /data/key.pem --cert /data/cert.pem https://${UCP_URL}"
    fi
  fi
else
  CURL_CMD="curl -s -m 5 --unix-socket /var/run/docker.sock http://v1.30"

  # check to see if the docker socket is available
  if [ ! -S /var/run/docker.sock ]
  then
    echo "ERROR: Docker socket not found at /var/run/docker.sock"
    exit 1
  fi
fi

# shellcheck disable=SC2086
# check to see if the engine is Swarm/is a manager by trying to get a token
if [ "$(${CURL_CMD}/swarm | jq -r .message)" != "null" ]
then
  echo "ERROR: Docker engine is not a Swarm manager"
  exit 1
fi

pull_node_data() {
  # output for type
  if [ "${2}" = "linux" ] || [ "${2}" = "windows" ]
  then
    echo -e "Data for ${1} nodes running ${2}:"
  else
    echo -e "Data for ${1} nodes:"
  fi

  # add filter for managers or workers
  if [ "${1}" = "manager" ] || [ "${1}" = "worker" ]
  then
    NODE_FILTER="?filters=%7B%22role%22%3A%7B%22${1}%22%3Atrue%7D%7D"
  else
    NODE_FILTER=""
  fi

  # see if we are looking for just linux or windows nodes
  if [ "${2}" = "linux" ] || [ "${2}" = "windows" ]
  then
    # shellcheck disable=SC2086
    # get the number of nano CPUs reported from Swarm on each node for the specified OS
    nanoCPUs="$(for NODE in $(${CURL_CMD}/nodes${NODE_FILTER} | jq -r '.[]|select(.Description.Platform.OS|contains("'"${2}"'"))|.ID'); do ${CURL_CMD}/nodes/"${NODE}" | jq -r .Description.Resources.NanoCPUs; done)"
  else
    # shellcheck disable=SC2086
    # get the number of nano CPUs reported from Swarm on each node
    nanoCPUs="$(for NODE in $(${CURL_CMD}/nodes${NODE_FILTER} | jq -r '.[]|.ID'); do ${CURL_CMD}/nodes/"${NODE}" | jq -r .Description.Resources.NanoCPUs; done)"
  fi

  # convery nano CPUs to CPUs
  CPUs=$(for i in ${nanoCPUs}; do echo "$((i/1000000000))"; done)

  # get the sum of all CPU counts
  ttlCPU="$(COUNT=0; TOTAL=0; for i in ${CPUs};do TOTAL=$(echo "${TOTAL}+${i}" | bc ); ((COUNT++)); done; echo "${TOTAL}")"

  # count the number of nodes reported
  NODE_COUNT=$(echo "${CPUs}" | wc -l)

  # find the average CPU count
  avgCPU="$(echo "scale=2; ${ttlCPU} / ${NODE_COUNT}" | bc)"

  # determine the smallest # CPUs per node
  minCPU="$(echo "${CPUs}" | sort -n | head -1)"

  # determine the largest # CPUs per node
  maxCPU="$(echo "${CPUs}" | sort -n | tail -n 1)"

  # find the unique CPU node sizes
  CPU_sizes="$(echo "${CPUs}" | sort -n | uniq)"

  # report the quantity of nodes that match a given number of CPUs
  for SIZE in ${CPU_sizes}; do echo -n "${SIZE} Core x "; echo "${CPUs}" | grep "${SIZE}" | sort -n | wc -l; done

  # report the rest of the data
  echo "
# Nodes - ${NODE_COUNT}
Ttl Core - ${ttlCPU}
Min Core - ${minCPU}
Max Core - ${maxCPU}
Avg Core - ${avgCPU}"
}

echo "========================"
pull_node_data all
echo "========================"
pull_node_data manager
echo "========================"
pull_node_data worker
echo "========================"
pull_node_data all linux
echo "========================"
pull_node_data all windows
echo "========================"
