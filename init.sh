#!/bin/bash

if [ ! -f "./config/detalk.yml" ]; then
  echo "Creating application config file..."
  cp ./config/detalk.example.yml ./config/detalk.yml
fi

echo "Starting container..."
docker-compose up -d

echo "Running migrations..."
docker-compose run --rm web bash -lc "bundle exec rake db:migrate"
