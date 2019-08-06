#!/bin/bash -ex


homepage=http://10.66.60.1:8000
attempts=60

function retry_get_homepage() {
  for i in $(seq 1 $attempts); do
    if curl -f "$homepage"; then return 0; fi
    sleep 5
  done
  echo "Homepage failed after $attempts attempts"
  exit 1
}

retry_get_homepage
