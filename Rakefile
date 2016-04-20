require 'unifi'
require 'dotenv/tasks'
require 'pry-byebug'
require_relative 'lib/unifi_client'

FAKE_DATA = true  # Enable in dev mode (no controller)

namespace :unifi do
  desc "Print a list of all devices currently connected"
  task devices: :dotenv do
    unifi = UnifiClient.new
    unifi.print_devices
  end
end

namespace :cobot do
  desc "Print a list of all active Cobot members"
  task members: :dotenv do
    # TODO
  end
end
