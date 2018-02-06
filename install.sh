#!/bin/sh
# This script is run on Hegerys by the post-receive git hook. AFTER EACH git push.

cd $1
/home/seb/.rbenv/shims/bundle install
cp ~/.env/alfred-coworker/.env .
/home/seb/.rbenv/shims/bundle exec rake -T
