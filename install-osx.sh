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
  error "calabash-sandbox only runs on Mac OSX"
  exit 1
fi

OS_MAJOR_VERSION=`uname -r | cut -d. -f1`

if [ "${OS_MAJOR_VERSION}" = "15" ]; then
  MACOS="macOS-10.11"
  DARWIN_VERSION="darwin15"
elif [ "${OS_MAJOR_VERSION}" = "16" ]; then
  MACOS="macOS-10.12"
  DARWIN_VERSION="darwin16"
else
  error "calabash-sandbox only runs on macOS El Cap and Sierra"
  exit 1
fi

is_command_in_path()
{
    command -v "$1" >/dev/null 2>&1
}

if is_command_in_path "rbenv"; then
  error "Detected that rbenv is already installed."
  error "You cannot use the calabash-sandbox."
  exit 1
fi

if is_command_in_path "rvm"; then
  error "Detected that rvm is already installed."
  error "You cannot use the calabash-sandbox."
  exit 1
fi

SANDBOX_DIR="${HOME}/.calabash/sandbox"
RUBY_VERSION="2.3.1"
RUBIES_DIR="${SANDBOX_DIR}/Rubies"
RUBY_PATH="${RUBIES_DIR}/${RUBY_VERSION}/bin"
RUBY_LIB="${RUBIES_DIR}/${RUBY_VERSION}/lib"
export GEM_HOME="${SANDBOX_DIR}/Gems"
export GEM_PATH="${RUBY_LIB}/ruby/gems/2.3.0:${GEM_HOME}:${GEM_HOME}/ruby/2.3.0"
OPENSSL_LIB="${RUBIES_DIR}/${RUBY_VERSION}/openssl/lib"
export RUBYLIB="${OPENSSL_LIB}:${RUBY_LIB}:${RUBY_LIB}/ruby/2.3.0/x86_64-${DARWIN_VERSION}:${RUBY_LIB}/ruby/2.3.0:${RUBY_LIB}/ruby/site_ruby/2.3.0"

if [ -d "${SANDBOX_DIR}" ]; then
  error "Sandbox already exists!"
  error ""
  error "If you want to update your sandbox:"
  error "  $ calabash-sandbox update"
  error ""
  error "If you want to reinstall the sandbox:"
  error "  $ rm -r ${SANDBOX_DIR}"
  error "and try again"
  exit 1
fi

set -e

banner "Installing Ruby ${RUBY_VERSION} for ${MACOS}"

mkdir -p "${GEM_HOME}"
mkdir -p "${RUBIES_DIR}"

URL="https://s3-eu-west-1.amazonaws.com/calabash-files/compiled-rubies/${RUBY_VERSION}/${MACOS}/${RUBY_VERSION}.zip"
curl -o "${RUBY_VERSION}.zip" --progress-bar "${URL}"

unzip -qo "${RUBY_VERSION}.zip" -d "${RUBIES_DIR}"
rm "${RUBY_VERSION}.zip"

OPENSSL_DIR="${HOME}/.calabash/sandbox/Rubies/2.3.1/openssl"
SSL_DYLIB="${OPENSSL_DIR}/lib/libssl.1.0.0.dylib"
CRYPTO_DYLIB="${OPENSSL_DIR}/lib/libcrypto.1.0.0.dylib"
RUBY_OPENSSL_BUNDLE="${RUBY_LIB}/ruby/2.3.0/x86_64-${DARWIN_VERSION}/openssl.bundle"
RUBY_DIGEST_DIR="${RUBY_LIB}/ruby/2.3.0/x86_64-${DARWIN_VERSION}/digest"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libssl.1.0.0.dylib" \
  "${SSL_DYLIB}" \
  "${RUBY_OPENSSL_BUNDLE}"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${RUBY_OPENSSL_BUNDLE}"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${RUBY_DIGEST_DIR}/md5.bundle"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${RUBY_DIGEST_DIR}/rmd160.bundle"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${RUBY_DIGEST_DIR}/sha1.bundle"

install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${RUBY_DIGEST_DIR}/sha2.bundle"

chmod +w "${SSL_DYLIB}"
install_name_tool -change \
  "/Users/clean/2.3.1/openssl/lib/libcrypto.1.0.0.dylib" \
  "${CRYPTO_DYLIB}" \
  "${SSL_DYLIB}"

chmod -w "${SSL_DYLIB}"

banner "Installing Gems"

echo "source 'https://rubygems.org'" > "${SANDBOX_DIR}/Gemfile"
echo "gem 'calabash-cucumber', '>= 0.20.4', '< 1.0'" >> "${SANDBOX_DIR}/Gemfile"
echo "gem 'calabash-android', '>= 0.9.0', '< 1.0'" >> "${SANDBOX_DIR}/Gemfile"
echo "gem 'xamarin-test-cloud', '>= 2.1.1', '< 3.0'" >> "${SANDBOX_DIR}/Gemfile"

info "Updating rubygems version"
(
cd ${SANDBOX_DIR};
PATH="${RUBY_PATH}:${GEM_HOME}/bin:${PATH}" \
    gem update --system > /dev/null
)

info "Installing bundler"
(
cd ${SANDBOX_DIR};
PATH="${RUBY_PATH}:${GEM_HOME}/bin:${PATH}" \
  gem install bundler > /dev/null
)

(
cd ${SANDBOX_DIR};
PATH="${RUBY_PATH}:${GEM_HOME}/bin:${PATH}" \
  bundle install
)

banner "Preparing the Sandbox"

SANDBOX_SCRIPT="./calabash-sandbox"

URL="https://raw.githubusercontent.com/calabash/install/master/calabash-sandbox"
curl -L -O --progress-bar "${URL}"

chmod a+x $SANDBOX_SCRIPT

echo ""

if [ -w "/usr/local/bin" ]; then
  echo "local bin writable"
  rm -rf /usr/local/bin/calabash-sandbox
  cp $SANDBOX_SCRIPT /usr/local/bin
  info "Installed /usr/local/bin/calabash-sandbox"
else
  warn "Unable to install calabash-sandbox globally:"
  warn "  /usr/local/bin is not writeable"
  warn ""
  warn "To install globally, run this command:"
  warn "  sudo mv calabash-sandbox /usr/local/bin"
fi

banner "Done!"

DROID=$( { echo "calabash-android version 1>&2" |  $SANDBOX_SCRIPT 1>/dev/null; } 2>&1)
IOS=$( { echo "calabash-ios version 1>&2" | $SANDBOX_SCRIPT 1>/dev/null; } 2>&1)
TESTCLOUD=$( { echo "test-cloud version 1>&2" | $SANDBOX_SCRIPT 1>/dev/null; } 2>&1)

info "Installed:"
info "      calabash-ios: $IOS"
info "  calabash-android: $DROID"
info "xamarin-test-cloud: $TESTCLOUD"
echo ""
info "$SANDBOX_SCRIPT update # to check for gem updates."
info "$SANDBOX_SCRIPT        # to get started!"
echo ""

