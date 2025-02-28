#!/usr/bin/env bash
set -o errexit  # Exit on error

# Fetch dependencies
mix deps.get --only prod
MIX_ENV=prod mix compile

# Generate a release (if applicable)
MIX_ENV=prod mix release --overwrite
