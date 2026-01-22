#!/usr/bin/env bash

language_detect() {
  find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | grep -q .
}

language_name() {
  echo "dotnet"
}

language_build() {
  dotnet build --configuration Release
}

language_test() {
  dotnet test --no-build
}
language_ship() {
  log_info "Dotnet ship extension active"
}