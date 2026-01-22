#!/usr/bin/env bash

language_detect() {
  [[ -f "package.json" ]]
}

language_name() {
  echo "node"
}

language_build() {
  npm install
  npm run build --if-present
}

language_test() {
  npm test --if-present
}
#!/usr/bin/env bash

language_ship() {
  log_info "Node ship extension active"
}
