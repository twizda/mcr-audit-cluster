# msr.ci.mirantis.com/twizda/audit-cluster

docker image for auditing a Swarm/MKE cluster to return the core counts and other sizing stats
based off of alpine:latest

To pull this image:
`docker pull msr.ci.mirantis.com/twizda/audit-cluster`

## Example usage

There are two methods to run this container:

1. [__On the cluster__](#on-the-cluster) - Run it directly on a manager via a client bundle (requires image pull access from Mirantis' MSR)

1. [__On a local engine__](#on-a-local-engine) - Run it on a local machine (such as Docker Desktop) and communicate to the MKE APIs using a client bundle

If you are running in a secured environment or use Docker Content Trust policy enforcement, you'll want to choose the 2nd option.  The first option is the quickest due to all API calls going over the Docker socket of a manager instead of across the MKE APIs but the 2nd option will not run any containers in your environment.

### On the cluster

1. Load an MKE client bundle (or skip the client bundle and run the command directly on a manager)

1. Run the container:

    ```
    docker run -t --rm --name audit-cluster \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e affinity:container==ucp-controller \
      msr.ci.mirantis.com/twizda/audit-cluster
    ```

1. Data will be returned:

    ```
    $ docker run -t --rm --name audit-cluster \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e affinity:container==ucp-controller \
        msr.ci.mirantis.com/twizda/audit-cluster
    ========================
    Data for all nodes:
    2 Core x 4
    4 Core x 11

    # Nodes - 15
    Ttl Core - 52
    Min Core - 2
    Max Core - 4
    Avg Core - 3.46
    ========================
    Data for manager nodes:
    4 Core x 3

    # Nodes - 3
    Ttl Core - 12
    Min Core - 4
    Max Core - 4
    Avg Core - 4.00
    ========================
    Data for worker nodes:
    2 Core x 4
    4 Core x 8

    # Nodes - 12
    Ttl Core - 40
    Min Core - 2
    Max Core - 4
    Avg Core - 3.33
    ========================
    Data for all nodes running linux:
    2 Core x 4
    4 Core x 9

    # Nodes - 13
    Ttl Core - 44
    Min Core - 2
    Max Core - 4
    Avg Core - 3.38
    ========================
    Data for all nodes running windows:
    4 Core x 2

    # Nodes - 2
    Ttl Core - 8
    Min Core - 4
    Max Core - 4
    Avg Core - 4.00
    ========================
    ```

   In the above example, the cluster has 15 nodes, 4 nodes have 2 cores each, 11 nodes have 4 cores each.

### On a local engine

1. Find the URL to your MKE and the local path to your _extracted_ client bundle.

1. Run the container locally, updating the `UCP_URL` and the path to your extracted client bundle:

    ```
    docker run -t --rm --name audit-cluster \
      -e UCP_URL="mke.example.com" \
      -v /path/to/your/client/bundle:/data:ro \
      msr.ci.mirantis.com/twizda/audit-cluster
    ```

1. Results will be returned:

    ```
    $ docker run -t --rm --name audit-cluster \
        -e UCP_URL="ucp.example.com" \
        -v /path/to/your/client/bundle:/data:ro \
        msr.ci.mirantis.com/twizda/audit-cluster
    ========================
    Data for all nodes:
    2 Core x 4
    4 Core x 11

    # Nodes - 15
    Ttl Core - 52
    Min Core - 2
    Max Core - 4
    Avg Core - 3.46
    ========================
    Data for manager nodes:
    4 Core x 3

    # Nodes - 3
    Ttl Core - 12
    Min Core - 4
    Max Core - 4
    Avg Core - 4.00
    ========================
    Data for worker nodes:
    2 Core x 4
    4 Core x 8

    # Nodes - 12
    Ttl Core - 40
    Min Core - 2
    Max Core - 4
    Avg Core - 3.33
    ========================
    ```

   In the above example, the cluster has 15 nodes, 4 nodes have 2 cores each, 11 nodes have 4 cores each.

### From an MKE cluster support bundle

If you wish to retrieve some basic data from an MKE cluster support bundle, you can utilize the `support_dump_count_cores.sh` script to analyze the dump locally.  There is less detailed information in the support dump as the data structure is different than the API calls but you can get general information about cluster size.
