#!/bin/bash
# Author: Randy Coburn
# Date: 03/03/2017
# Description: This script is used to help deploy build and upload the
# terraform-runner container. It allows the container to be pushed to dockerhub
# with the lables containing the version of the runner gem and Terraform.
# It does require that the following Environment variables are set:
# DOCKER_USER=<docker hub username>
# DOCKER_PASS=<docker hub password>
#

# Default variables that are used later.
PUSH=false
PUSHLATEST=false
#TERRAFORM_VERSION=""
#TERRAFORM_RUNNER_VERSION=""
# Get and digest the arguments.
for i in "$@"; do
    case $i in
        -TERRAFORM_VERSION=*)
            TERRAFORM_VERSION="${i#*=}"
            shift
            ;;
        -TERRAFORM_RUNNER_VERSION=*)
            TERRAFORM_RUNNER_VERSION="${i#*=}"
            shift
            ;;
        --push-to-docker)
            PUSH=true
            if [[ -z $DOCKER_USER ]] || [[ -z $DOCKER_PASS ]]; then
                echo "################################################################"
                echo "Remeber to set docker username and password if you want to push."
                echo "export DOCKER_USER="
                echo "export DOCKER_PASS="
                echo "################################################################"

                [[ -z $DOCKER_USER ]] && echo "DOCKER_USER not set"; exit 1
                [[ -z $DOCKER_PASS ]] && echo "DOCKER_PASS not set"; exit 1
            fi
            shift
            ;;
        --push-as-latest)
            PUSHLATEST=true
            shift
            ;;
        -h)
            echo "This script is used to build the terraform runner container."
            echo "Valid options are:"
            echo "  -TERRAFORM_VERSION=x.x.x"
            echo "  -TERRAFORM_RUNNER_VERSION=x.x.x"
            echo "  --push-to-docker"
            echo "  --push-as-latest"
            echo "  -h for this screen."
            exit 1
            ;;
        *)
            # unknown option
            echo "$i is not vaild"
            exit 1
        ;;
    esac;
done

if [[ -z $TERRAFORM_VERSION ]]; then
    echo "TERRAFORM_VERSION not set"
    exit 1
fi
if [[ -z $TERRAFORM_RUNNER_VERSION ]]; then
    echo "TERRAFORM_RUNNER_VERSION not set"
    exit 1
fi

docker build --build-arg TERRAFORM_VERSION=$TERRAFORM_VERSION \
             --build-arg TERRAFORM_RUNNER_VERSION=$TERRAFORM_RUNNER_VERSION \
             --tag=morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION} \
             .
EXITCODE=$?
if [ $EXITCODE -eq 0 ]; then

    echo "Build Successful process to version check"
    if [ $(docker run morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION} /terraform-runner/terraform-runner -v | grep -c $TERRAFORM_RUNNER_VERSION) -ge 1 ] && \
    [ $(docker run morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION} /usr/local/bin/terraform -v | grep -c $TERRAFORM_VERSION) -ge 1 ]; then
        echo "Correct versions detected."

        if $PUSH; then
            echo "Container shipping requested."
            docker login -u $DOCKER_USER -p $DOCKER_PASS
            if [ $? -eq 0 ]; then
                echo "pushing contianer morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION}"
                docker push morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION}
                if $PUSHLATEST; then
                    echo "Push as latest requested."
                    echo "pushing contianer morfien101/terraform-runner"
                    docker tag morfien101/terraform-runner:${TERRAFORM_VERSION}_${TERRAFORM_RUNNER_VERSION} morfien101/terraform-runner:latest
                    docker push morfien101/terraform-runner
                fi
                docker logout
            fi
        fi
    fi
else
    echo "Build failed exiting bad."
    exit 1
fi
