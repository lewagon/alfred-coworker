require 'unifi'
require 'dotenv/tasks'
require 'pry-byebug'
require 'faraday'
require 'faraday_middleware'
require 'cobot_client'
require 'uri'
require 'net/http'
require 'net/https'
require_relative 'lib/unifi_client'

FAKE_DATA = false  # Enable in dev mode (no controller)

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
    # Check out the generated tokens here: https://www.cobot.me/oauth2_clients
    #
    # https://www.cobot.me/api-docs/oauth-flow#app-flow

    conn = Faraday.new(:url => 'https://www.cobot.me') do |faraday|
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter  Faraday.default_adapter
    end

    response = conn.post '/oauth/access_token' do |req|
      req.params = {
        grant_type: 'password',
        # scope:  specified here: https://www.cobot.me/oauth2_clients/e465154e42b61526d3149602987aac4c/edit
        username: ENV['COBOT_USERNAME'],
        password: ENV['COBOT_PASSWORD'],
        client_id: ENV['COBOT_CLIENT_ID'],
        client_secret: ENV['COBOT_CLIENT_SECRET']
      }
    end

    puts "Here's your token"
    puts "👉  #{response.body["access_token"]}"
  end

  desc "Print a list of all active Cobot members"
  task members: :dotenv do
    cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
    members = cobot.get('lewagon', '/memberships')
    members.each do |m|
      custom_fields = cobot.get('lewagon', "/memberships/#{m[:id]}/custom_fields")[:fields].find { |e| e[:label] == "mac_address" }[:value]
      puts "#{m[:name].rjust(30)} (#{m[:id]}) - #{m[:plan][:name]} - #{custom_fields}"
    end
    puts "#{members.count} members"
  end

  namespace :time_pass do
    desc "Create a dont_charge time pass for a member"
    task :create, [ :membership_id ] => :dotenv do |t, args|
      membership_id = args[:membership_id]
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      pass = {
        "no_of_passes": 1,
        "charge": "dont_charge",
        "id": "0"  # Day Pass
      }
      puts cobot.post('lewagon', "/memberships/#{membership_id}/time_passes", pass)
    end

    desc "List unused time passes for a member"
    task :unused, [ :membership_id ] => :dotenv do |t, args|
      membership_id = args[:membership_id]
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      p cobot.get('lewagon', "/memberships/#{membership_id}/time_passes/unused")
    end
  end

  namespace :check_in do
    desc "Check-in a member"
    task :create, [ :membership_id ] => :dotenv do |t, args|
      membership_id = args[:membership_id]
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])

      puts cobot.post('lewagon', "/memberships/#{membership_id}/work_sessions")
    end

    desc "List all today's check-ins"
    task list: :dotenv do |t, args|
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      cobot.get('lewagon', '/check_ins').each do |c|
        puts "#{c[:membership][:name].rjust(30)} (#{c[:membership_id]}) - #{c[:valid_from]}"
      end
    end

    desc "'main' rake task to check-in all connected users"
    task create_for_connected_devices: :dotenv do
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      connected_devices = UnifiClient.new.devices
      members = cobot.get('lewagon', '/memberships')
      check_ins = cobot.get('lewagon', '/check_ins')

      connected_mac_addresses = connected_devices.map(&:mac).map(&:downcase)

      members.each do |m|
        mac_address = cobot.get('lewagon', "/memberships/#{m[:id]}/custom_fields")[:fields].find { |e| e[:label] == "mac_address" }[:value]
        unless mac_address == nil || mac_address == ""
          mac_address.downcase!
          if connected_mac_addresses.include?(mac_address)                # Connected to Wifi
            if !check_ins.map { |c| c[:membership_id] }.include?(m[:id])  # Not already Checked-in
              puts "#{m[:name]} is connected to Wifi. Checking-in..."

              begin
                time_passes = cobot.get('lewagon', "/memberships/#{m[:id]}/time_passes/unused")
                if time_passes.length == 0
                  puts "No more ticket for #{m[:name]}, buying one..."
                  pass = {
                    "no_of_passes": 1,
                    "charge": "charge",
                    "id": "0"  # Day Pass
                  }
                  puts cobot.post('lewagon', "/memberships/#{m[:id]}/time_passes", pass)
                end
                response = cobot.post('lewagon', "/memberships/#{m[:id]}/work_sessions")
                puts "#{m[:name]} has been successfully checked-in."

                # Post to Slack
                uri = URI.parse(ENV['SLACK_INCOMING_WEBHOOK_URL'])
                https = Net::HTTP.new(uri.host, uri.port)
                https.use_ssl = true
                request = Net::HTTP::Post.new(
                  uri.request_uri, {'Content-Type' =>'application/json'})
                request.body = JSON.generate({ text: "#{m[:name]} has checked-in." })
                https.request(request)

              rescue CobotClient::UnprocessableEntity
                # Already checked-in. Should not arrive here.
              end
            else
              puts "#{m[:name]} has already been checked-in for today."
            end
          end
        end
      end
    end
  end
end
