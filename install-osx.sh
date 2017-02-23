#!/usr/bin/env bash

# Green
function info {
  if [ "${TERM}" = "dumb" ]; then
    echo "INFO: $1"
  else
    echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
  fi
}

# Yellow
function warn {
  if [ "${TERM}" = "dumb" ]; then
    echo "WARN: $1"
  else
    echo "$(tput setaf 3)WARN: $1$(tput sgr0)"
  fi
}

# Red
function error {
  if [ "${TERM}" = "dumb" ]; then
    echo "ERROR: $1"
  else
    echo "$(tput setaf 1)ERROR: $1$(tput sgr0)"
  fi
}

# Magenta
function banner {
  if [ "${TERM}" = "dumb" ]; then
    echo ""
    echo "######## $1 ########"
    echo ""
  else
    echo ""
    echo "$(tput setaf 5)######## $1 ########$(tput sgr0)"
    echo ""
  fi
}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "calabash-sandbox only runs on Mac OSX"
  exit 1
fi

is_command_in_path()
{
    command -v "$1" >/dev/null 2>&1
}

if is_command_in_path "rbenv"; then
  echo "Detected that rbenv is already installed."
  echo "You cannot use the calabash-sandbox."
  exit 1
fi

if is_command_in_path "rvm"; then
  echo "Detected that rvm is already installed."
  echo "You cannot use the calabash-sandbox."
  exit 1
fi

export GEM_HOME="${HOME}/.calabash/sandbox/Gems"
CALABASH_RUBIES_HOME="${HOME}/.calabash/sandbox/Rubies"
CALABASH_RUBY_VERSION="2.3.1"
SANDBOX="${HOME}/.calabash/sandbox"
CALABASH_SANDBOX="calabash-sandbox"

# Don't auto-overwrite the sandbox if it already exists
if [ -d "${SANDBOX}" ]; then
  echo "Sandbox already exists!"
  echo "Please delete the directory:"
  echo ""
  echo "  ${SANDBOX}"
  echo ""
  echo "and try again."
  exit 1
fi

mkdir -p "$GEM_HOME"
mkdir -p "${HOME}/.calabash/sandbox/Rubies"

#Download Ruby
echo "Preparing Ruby ${CALABASH_RUBY_VERSION}..."

URL="https://s3-eu-west-1.amazonaws.com/calabash-files/${CALABASH_RUBY_VERSION}.zip"
curl -o \
  "${CALABASH_RUBY_VERSION}.zip" \
  --progress-bar "${URL}"

unzip -qo "${CALABASH_RUBY_VERSION}.zip" -d "${CALABASH_RUBIES_HOME}"
rm "${CALABASH_RUBY_VERSION}.zip"

#Download the gems and their dependencies
echo "Installing gems, this may take a little while..."

CALABASH_GEMS_FILE="CalabashGems.zip"
if [ "${DEV}" == 1 ]; then
  CALABASH_GEMS_FILE="calabash-sandbox/dev/CalabashGems.zip"
  echo "[DEBUG]: Using calabash gems file: ${CALABASH_GEMS_FILE}"
fi

curl -o \
  "CalabashGems.zip" \
  --progress-bar https://s3-eu-west-1.amazonaws.com/calabash-files/${CALABASH_GEMS_FILE}

unzip -qo "CalabashGems.zip" -d "${SANDBOX}"
rm "CalabashGems.zip"

#ad hoc Gemfile
echo "source 'https://rubygems.org'" > "${SANDBOX}/Gemfile"
echo "gem 'calabash-cucumber', '>= 0.20.4', '< 1.0'" >> "${SANDBOX}/Gemfile"
echo "gem 'calabash-android', '>= 0.9.0', '< 1.0'" >> "${SANDBOX}/Gemfile"
echo "gem 'xamarin-test-cloud', '>= 2.1.1', '< 3.0'" >> "${SANDBOX}/Gemfile"

#Download the Sandbox Script
echo "Preparing sandbox..."
if [ "${DEBUG}" == 1 ]; then
  echo "Downloading sandbox from ${SANDBOX_URL}"
fi

curl -L -O \
  --progress-bar "${SANDBOX_URL}"

chmod a+x $CALABASH_SANDBOX
mv $CALABASH_SANDBOX /usr/local/bin
if [ $? -ne 0 ]; then
  CALABASH_SANDBOX="./calabash-sandbox"
  echo -e "\033[0;33m[Warning]:\033[00m Unable to install globally, /usr/local/bin is not writeable"
  echo "To install globally, run this command:"
  echo ""
  echo -e "'\033[0;33msudo mv calabash-sandbox /usr/local/bin\033[00m'"
fi

DROID=$( { echo "calabash-android version 1>&2" |  $CALABASH_SANDBOX 1>/dev/null; } 2>&1)
IOS=$( { echo "calabash-ios version 1>&2" | $CALABASH_SANDBOX 1>/dev/null; } 2>&1)
TESTCLOUD=$( { echo "test-cloud version 1>&2" | $CALABASH_SANDBOX 1>/dev/null; } 2>&1)

echo "Done! Installed:"
echo -e "\033[0;33mcalabash-ios:       $IOS"
echo "calabash-android:   $DROID"
echo -e "xamarin-test-cloud: $TESTCLOUD\033[00m"
echo -e "Execute '\033[0;32m$CALABASH_SANDBOX update\033[00m' to check for gem updates."
echo -e "Execute '\033[0;32m$CALABASH_SANDBOX\033[00m' to get started! "
echo
