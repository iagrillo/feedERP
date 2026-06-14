#!/bin/bash

# Install Flutter
git clone https://github.com/flutter/flutter.git --depth 1
export PATH="./flutter/bin:"

# Get Flutter version to verify installation
flutter --version

# Get dependencies
flutter pub get

# Build web
flutter build web --release
