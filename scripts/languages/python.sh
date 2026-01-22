#!/usr/bin/env bash

language_detect() {
  [[ -f "pyproject.toml" || -f "requirements.txt" ]]
}

language_name() {
  echo "python"
}

language_build() {
  pip install -r requirements.txt
}

language_test() {
  pytest || true
}
language_ship() {
  log_info "Python ship extension active"
}