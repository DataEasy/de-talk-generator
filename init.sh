#!/bin/bash

if [ ! -f "./config/detalk.yml" ]; then
  echo "Creating application config file..."
  cp ./config/detalk.example.yml ./config/detalk.yml
fi

echo "Building the image..."
docker-compose --project-name detalk build --force-rm web

# Create a secret_key inside the container
echo "Generating production secret_key..."
PRODUCTION_SECRET_KEY=$(docker-compose run --rm web rake secret 2>/dev/null)

# Replace {{PRODUCTION_SECRET_KEY}} in docker-compose.yml for the secret_key generated 
sed -i'' -e "s|{{PRODUCTION_SECRET_KEY}}|$PRODUCTION_SECRET_KEY|" ./docker-compose.yml

echo "Creating database..."
docker-compose run --rm web rake db:create

echo "Running migrations..."
docker-compose run --rm web rake db:migrate

echo "Seeding data..."
docker-compose run --rm web rake db:seed

echo "Starting container..."
docker-compose up -d