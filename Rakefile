require 'unifi'
require 'dotenv/tasks'
require 'pry-byebug'

task scan: :dotenv do
  controller = Unifi::Controller.new(host: ENV['UNIFI_CONTROLLER_ADDRESS'])
  controller.login
  # clients = controller.clients.map { |c| OpenStruct.new(c) }
  clients = JSON.load(File.read "devices.json")["data"].map { |c| OpenStruct.new(c) }
  clients.each do |c|
    puts "#{c.ip.rjust(10)} - #{c.mac} - #{c.hostname}"
  end
end
