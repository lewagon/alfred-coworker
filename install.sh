#!/bin/sh
# This script is run on Hegerys by the post-receive git hook. AFTER EACH git push.

export PATH="~/.rbenv/bin:${PATH}"
eval "$(rbenv init -)"

cd $1
bundle install
cp ~/.env/alfred-coworker/.env .
bundle exec rake -T
