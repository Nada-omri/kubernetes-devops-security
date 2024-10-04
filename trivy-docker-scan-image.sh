#!/bin/bash

# Image to scan
DOCKER_IMAGE_NAME=$1

# Run Trivy scan on the Docker image
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_IMAGE_NAME

# Capture the exit code of the Trivy scan
exit_code=$?

# Output scan results
if [[ "$exit_code" -ne 0 ]]; then
  echo "Image scanning failed. Vulnerabilities found."
  exit 1
else
  echo "Image scanning passed. No HIGH or CRITICAL vulnerabilities found."
fi
