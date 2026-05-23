#!/usr/bin/env bash
# Regenerates Tompero.xcodeproj from project.yml and re-integrates Pods.
# Run this after adding or removing files on disk, or after editing project.yml.
#
# Files added through Xcode's "New File" UI will NOT survive — always create on
# disk and let the source-glob in project.yml pick them up.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not installed. brew install xcodegen" >&2
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "cocoapods not installed. brew install cocoapods" >&2
  exit 1
fi

xcodegen generate
pod install

echo
echo "Done. Open Tompero.xcworkspace."
