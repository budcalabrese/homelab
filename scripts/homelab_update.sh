#!/usr/bin/env bash

echo "Updating Ollama models"
# updating local ollama models
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}
# setting ollama to listen on all ips  
launchctl setenv OLLAMA_HOST "0.0.0.0"

echo "Updating Docker images and containers"
# switching to the docker compose stack file
cd /Users/bud/home_space/homelab

# updating docker container images from registries
docker compose pull

# force rebuild all custom containers without cache
echo "Rebuilding custom containers without cache"
docker compose build --no-cache

# updating docker containers
echo "Running updated containers"
docker compose up -d

# pruning docker containers
echo "Pruning Docker images"
docker image prune -a -f

# updating homebrew packages
brew update && brew upgrade && brew cleanup && brew doctor  

# updating claude code
npm install -g @anthropic-ai/claude-code@latest

# sync obsidian vault to github
echo "Syncing Obsidian vault to GitHub"
/Users/bud/home_space/obsidian-vault/sync-obsidian.sh
