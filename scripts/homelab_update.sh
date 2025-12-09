#!/usr/bin/env bash

echo "Updating Ollama models"
# updating local ollama models
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}
# setting ollama to listen on all ips  
launchctl setenv OLLAMA_HOST "0.0.0.0"

echo "Updating Docker images and containers"
# switching to the docker compose stack file 
cd /Users/bud/home_space/homelab
# updating docker container images 
docker compose pull

# updating docker containers
echo "Running new Docker images"
docker compose up -d --build

# pruning docker containers
echo "Pruning Docker images"
docker image prune -a -f

# updating homebrew packages
brew update && brew upgrade && brew cleanup && brew doctor  