#!/bin/bash

set -exuo pipefail

VERSION=$(cat VERSION)

function install_hub() {
    sudo apt update && sudo apt install -y git wget
    url="$(wget -qO- https://api.github.com/repos/github/hub/releases/latest | tr '"' '\n' | grep '.*/download/.*/hub-linux-amd64-.*.tgz')"
    wget -qO- "$url" | sudo tar -xzvf- -C /usr/bin --strip-components=2 --wildcards "*/bin/hub"
}

function login_to_rubygems() {
  mkdir -p "$HOME/.gem"
  touch "$HOME/.gem/credentials"
  chmod 0600 "$HOME/.gem/credentials"
  printf -- "---\n:rubygems_api_key: %s\n" "$GEM_HOST_API_KEY" > "$HOME/.gem/credentials"
}

function tag_version() {
  GITHUB_TOKEN="${GITHUB_TOKEN}" hub release create -m "v${VERSION}" "v${VERSION}"
}


function publish_new_version() {
  set +x
  # Build and push gem
  gem build ./*.gemspec
  gem push ./*.gem

  # Create gh tag
  tag_version

  set -x
}
