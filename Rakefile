require 'unifi'
require 'dotenv/tasks'
require 'pry-byebug'
require 'faraday'
require 'faraday_middleware'
require 'cobot_client'
require 'uri'
require 'net/http'
require 'net/https'
require 'awesome_print'
require 'redis'
require 'date'
require 'json'
require 'rest-client'
require_relative 'lib/unifi_client'

FAKE_DATA = false  # Enable in dev mode (no controller)

def post_to_slack(message)
  uri = URI.parse(ENV['SLACK_INCOMING_WEBHOOK_URL'])
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(
    uri.request_uri, {'Content-Type' =>'application/json'})
  request.body = JSON.generate({ text: message })
  https.request(request)
end

def today_check_ins_key
  "check_ins:#{Date.today.to_s}"
end

$redis = Redis.new

namespace :redis do
  desc "PING Redis"
  task ping: :dotenv do
    puts $redis.ping
  end
end

namespace :unifi do
  desc "Print a list of all clients currently connected"
  task clients: :dotenv do
    unifi = UnifiClient.new
    unifi.print_clients
  end

  desc "Print a list of all devices (APs) currently connected"
  task devices: :dotenv do
    unifi = UnifiClient.new
    unifi.print_devices
  end

  desc "Detect squatters"
  task squatters: :dotenv do |t, args|
    unifi = UnifiClient.new
    unifi.clients.each do |client|
      if client.name && client.name[0] == '['
        # OK, sorted on Unifi
      elsif client.hostname =~ /ipad|iphone|android|galaxy/i
        # OK, that's a mobile
      else
        device_name = unifi.devices[client.ap_mac]&.name
        message = "#{client.hostname} (#{client.mac} - #{client.oui}) connected to #{device_name} #{(client._uptime_by_ugw || 0) / 60} minute(s) ago"
        puts message

        # Post to Slack
        key = "#{client.mac}:#{Date.today.to_s}:slack"
        if $redis.get(key)
          # Ignore, alert has already been sent to Slack
        else
          post_to_slack(":warning: Squatter? #{message}")
          $redis.set(key, 'send')
          $redis.expire(key, 3600 * 24)
        end
      end
    end
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
      binding.pry
      custom_fields = cobot.get('lewagon', "/memberships/#{m[:id]}/custom_fields")[:fields]
      mac_address = custom_fields.find { |e| e[:label] == "mac_address" }[:value] || ""
      github_nickname = custom_fields.find { |e| e[:label] == "github_nickname" }[:value] || ""
      puts "#{m[:name].ljust(30)} - #{mac_address.ljust(17)} - #{github_nickname.ljust(15)} - https://lewagon.cobot.me/admin/memberships/#{m[:id]}"
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
        "charge": "charge",
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

  namespace :plan do
    desc "List plans for space"
    task list: :dotenv do
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      ap cobot.get('lewagon', '/plans')
    end
  end

  namespace :invoice do
    desc "List invoices for a member"
    task :list, [ :membership_id ] => :dotenv do |t, args|
      membership_id = args[:membership_id]
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])

      cobot.get('lewagon', "/memberships/#{membership_id}/invoices").map { |invoice| pp invoice }
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
    task create_for_connected_clients: :dotenv do
      cobot = CobotClient::ApiClient.new(ENV['COBOT_ACCESS_TOKEN'])
      connected_clients = UnifiClient.new.clients
      members = cobot.get('lewagon', '/memberships')
      check_ins = cobot.get('lewagon', '/check_ins')

      connected_mac_addresses = connected_clients.map(&:mac).map(&:downcase)

      members.each do |m|
        custom_fields = cobot.get('lewagon', "/memberships/#{m[:id]}/custom_fields")[:fields]
        mac_addresses = custom_fields.find { |e| e[:label] == "mac_address" }[:value]
        mac_addresses = (mac_addresses || "").split(",").map { |m| m.strip.downcase }
        unless mac_addresses.size == 0
          if mac_addresses.any? { |m| connected_mac_addresses.include?(m) } # Connected to Wifi
            if !check_ins.map { |c| c[:membership_id] }.include?(m[:id])    # Not already Checked-in
              puts "#{m[:name]} is connected to Wifi. Checking-in..."

              # Is this mac address a TA?
              github_nickname = custom_fields.find { |e| e[:label] == "github_nickname" }[:value] || ""
              ta = false
              unless github_nickname !~ /\S/
                # Is this TA working today?
                puts "Ah ah, we have a TA! #{github_nickname}"
                response = JSON.parse(RestClient.get "https://kitt.lewagon.com/api/v1/users/works_today?github_nickname=#{github_nickname}")
                if response['works_today']
                  # Time to add some credits
                  puts "And that's a work day. Adding 4 days (including current one) as free credit!"
                  free_passes = 3
                  pass = {
                    "no_of_passes": free_passes + 1, # +1 for today's check-in
                    "charge": "dont_charge",
                    "id": "0"  # Day Pass
                  }
                  cobot.post('lewagon', "/memberships/#{m[:id]}/time_passes", pass)
                  message = ":ticket: #{m[:name]} (#{github_nickname}) is a TA today. Granting #{free_passes} free passes for future days."
                  puts message
                  post_to_slack(message)
                  ta = true
                else
                  puts "But he/she's not working today..."
                end
              end

              # Is this the first time we see this member?
              existing_check_ins = cobot.get('lewagon', "/memberships/#{m[:id]}/check_ins/", from: Date.new(2016, 1, 1), to: Date.today)
              if existing_check_ins.length == 0
                # First day is free!

                pass = {
                  "no_of_passes": 1,
                  "charge": "dont_charge",
                  "id": "0"  # Day Pass
                }
                cobot.post('lewagon', "/memberships/#{m[:id]}/time_passes", pass)
                message = ":free: #{m[:name]} is new in the Cowork. Granting 1 free pass for first day!"
                puts message
                post_to_slack(message)
              end

              begin
                time_passes = cobot.get('lewagon', "/memberships/#{m[:id]}/time_passes/unused")
                if time_passes.length == 0
                  puts "No more ticket for #{m[:name]}, buying one..."
                  pass = {
                    "no_of_passes": 1,
                    "charge": "charge",
                    "id": "0"  # Day Pass
                  }
                  cobot.post('lewagon', "/memberships/#{m[:id]}/time_passes", pass)
                end
                response = cobot.post('lewagon', "/memberships/#{m[:id]}/work_sessions")

                unless ta
                  coworkers = $redis.incr(today_check_ins_key)
                  if coworkers == 1
                    message = ":sunrise: Say hello to #{m[:name]}, today's first coworker!"
                  else
                    message = "#{m[:name]} has been successfully checked-in, #{coworkers} for today"
                  end
                  if coworkers % 10 == 0
                    message = ":tada: #{message}"
                  end
                  puts message

                  # Post to Slack
                  post_to_slack(message)
                end
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
