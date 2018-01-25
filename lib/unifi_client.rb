class UnifiClient
  def clients
    @clients ||= fetch_clients
  end

  def devices
    @fetch_devices ||= fetch_devices
  end

  def print_clients
    clients.each do |c|
      # #{c.ip.rjust(10)} -
      if c.name && c.name[0] == '['
        puts "[OK] #{c.mac} - #{devices[c.ap_mac]&.name} - #{c.name} (#{c.oui})"
      elsif c.hostname =~ /ipad|iphone|android|galaxy/i
        puts "[OK] #{c.mac} - #{devices[c.ap_mac]&.name} - #{c.hostname} (#{c.oui})"
      else
        puts "[??] #{c.mac} - #{devices[c.ap_mac]&.name} - #{c.hostname} (#{c.oui})"
      end
    end
    puts "🖥  Found #{@clients.size} clients"
  end

  def print_devices
    devices.each do |mac, d|
      puts "#{mac} - #{d.name}"
    end
  end

  private

  def fetch_clients
    if ::FAKE_DATA
      json_clients = JSON.load(File.read(File.expand_path('../../clients.json', __FILE__)))["data"]
    else
      controller = Unifi::Controller.new(host: ENV['UNIFI_CONTROLLER_ADDRESS'], site: ENV["UNIFI_SITE"])
      controller.login
      json_clients = controller.clients
    end
    json_clients.map { |c| OpenStruct.new(c) }
  end

  def fetch_devices
    controller = Unifi::Controller.new(host: ENV['UNIFI_CONTROLLER_ADDRESS'], site: ENV["UNIFI_SITE"])
    controller.login
    json_devices = controller.devices
    json_devices.reduce(Hash.new) { |h, c| h[c["mac"]] = OpenStruct.new(c); h }
  end
end
