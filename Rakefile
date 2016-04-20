require 'unifi'
require 'dotenv/tasks'
require 'pry-byebug'
require 'faraday'
require 'faraday_middleware'
require 'cobot_client'
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
  desc "Generate a new Cobot access token"
  task token: :dotenv do
    # https://www.cobot.me/api-docs/oauth-flow#app-flow

    conn = Faraday.new(:url => 'https://www.cobot.me') do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter  Faraday.default_adapter
    end

    response = conn.post '/oauth/access_token' do |req|
      req.params = {
        grant_type: 'password',
        username: ENV['COBOT_USERNAME'],
        password: ENV['COBOT_PASSWORD'],
        client_id: ENV['COBOT_CLIENT_ID'],
        client_secret: ENV['COBOT_CLIENT_SECRET']
      }
    end

    puts "Here's your token (for scope #{ENV['COBOT_SCOPE']}):"
    puts "👉  #{response.body["access_token"]}"
  end

  desc "Print a list of all active Cobot members"
  task members: :dotenv do
    cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
    members = cobot.get('lewagon', '/memberships')
    members.each do |m|
      puts "#{m[:name].rjust(30)} - #{m[:plan][:name]}"
    end
    puts "#{response.count} members"
  end
end
