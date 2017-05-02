## Publish a Ruby Version

### 1. Create a `clean` user on macOS. 

The latest Xcode must be installed.

Use System Preferences > Users.  The user should be a Standard user.

```
# Log into the clean user
$ su -l clean
```

The key is to ensure that the PATH does not include `/usr/local` because we do not want ruby-build to link any files in `/usr/local` during compilation.

```
# 1. Create a ~/.bash_profile
export PATH=".:/Users/clean/bin:/usr/libexec:/usr/bin:/bin:/usr/sbin:/sbin"
export PS1="[\h:\w]: \u$ "

# 2. Install shebang script in /Users/clean/bin
$ mkdir ~/bin
$ curl -sSL https://rawgit.com/calabash/install/master/bin/replace-shebang-lines.rb > ~/bin/replace-shebang-line.rb

# 3. Exit back to your user
$ exit

# 4. Check the PATH
$ su -l clean
$ echo $PATH
```

### 2. Install ruby-build from sources

If something goes wrong, follow the stand-alone instructions in the ruby-build README.

https://github.com/rbenv/ruby-build

```
$ su -l clean
$ mkdir -p ~/git/ruby-build
$ cd ~/git
$ git clone https://github.com/rbenv/ruby-build.git
$ cd ruby-build
# Installs ~/bin/ruby-build
$ PREFIX=~/ ./install.sh
```

### 3. Build the new Ruby version

```
$ cd ~/git/ruby-build
$ git checkout master
$ git pull

# Ensure the Xcode version
$ xcrun xcodebuild -version

# Installs ruby to ~/git/ruby-build/2.3.1
$ ruby-build 2.3.1 2.3.1
```

This will also build and link against an openssl library which we will distribute in the ruby .zip.

### 4. Update the rubygems version

```
$ cd ~/git/ruby-build/2.3.1
$ PATH=bin/ gem update --system
```

### 5. Update the rubygems ssl certs

See the [RubyGems help page](http://guides.rubygems.org/ssl-certificate-update/#manual-solution-to-ssl-issue) for the latest .pem.

```
$ cd ~/git/ruby-build/2.3.1
$ export PEMURL=https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/index.rubygems.org/GlobalSignRootCA.pem
$ curl -sSL $PEMURL > lib/ruby/2.3.0/rubygems/ssl_certs/GlobalSignRootCA.pem
```

### 6. Fix shebangs in ruby scripts

```
$ cd ~/git/ruby-build/
$ replace-shebang-lines.rb 2.3.1
```

### 7. Zip the ruby and push to S3

```
# Create the zip
$ cd ~/git/ruby-build
$ zip -r 2.3.1.zip 2.3.1

# Copy to user with S3 push privileges
$ exit
$ sudo cp /Users/clean/git/ruby-build/2.3.1.zip ~/Downloads

Automating S3 publish is a WIP
```
