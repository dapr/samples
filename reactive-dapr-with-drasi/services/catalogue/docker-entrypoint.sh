#!/bin/bash

# Start nginx
nginx -g 'daemon off;' &

# Start FastAPI app
cd /app/code && uvicorn main:app --host 0.0.0.0 --port 8000