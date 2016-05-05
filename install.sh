#!/bin/sh
# This script is run on Hegerys by the post-receive git hook. AFTER EACH git push.

cd $1
bundle install
bundle exec rake -T
