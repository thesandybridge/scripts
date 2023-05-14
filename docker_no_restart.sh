#! /bin/bash

disable_restart() {
    for container_id in $(docker ps -aq)
    do
        docker update --restart=no $container_id
    done
}
