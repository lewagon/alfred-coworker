#!/bin/sh
# This script is run on Hegerys by the post-receive git hook. AFTER EACH git push.

echo $1
cd $1
bundle install
rake -T
