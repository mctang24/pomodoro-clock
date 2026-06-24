#!/bin/sh
set -eu

REPO_URL="${POMODORO_REPO_URL:-https://github.com/mctang24/pomodoro-clock/archive/refs/heads/main.tar.gz}"
INSTALL_DIR="${HOME}/.local/bin"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

command -v swift >/dev/null 2>&1 || {
  echo "Swift is required. Install Xcode Command Line Tools first: xcode-select --install" >&2
  exit 1
}

mkdir -p "$INSTALL_DIR"

echo "Downloading Pomodoro..."
curl -fsSL "$REPO_URL" | tar -xz -C "$TMP_DIR" --strip-components 1

BUILD_DIR="$(swift build -c release --package-path "$TMP_DIR" --show-bin-path)"

echo "Building pomodoro CLI... this may take a minute"
swift build -c release --package-path "$TMP_DIR" --product pomodoro >/dev/null

echo "Building Pomodoro menu bar app... this may take a minute"
swift build -c release --package-path "$TMP_DIR" --product PomodoroApp >/dev/null

echo "Installing..."
cp "$BUILD_DIR/pomodoro" "$INSTALL_DIR/pomodoro"
cp "$BUILD_DIR/PomodoroApp" "$INSTALL_DIR/PomodoroApp"
rm -rf "$INSTALL_DIR/Pomodoro_PomodoroSupport.bundle"
cp -R "$BUILD_DIR/Pomodoro_PomodoroSupport.bundle" "$INSTALL_DIR/Pomodoro_PomodoroSupport.bundle"
chmod +x "$INSTALL_DIR/pomodoro" "$INSTALL_DIR/PomodoroApp"

echo "Installed: $INSTALL_DIR/pomodoro"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "Add to PATH: export PATH="$INSTALL_DIR:\$PATH"" ;;
esac
