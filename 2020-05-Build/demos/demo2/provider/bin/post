#!/bin/bash

set -o errexit
set -o pipefail

curl -d '{"lang":"en", "text":"I am so happy this worked"}' \
     -H "Content-type: application/json" \
     "http://localhost:3500/v1.0/invoke/processor/method/sentiment-score"