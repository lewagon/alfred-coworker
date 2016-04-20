class UnifiClient
  def devices
    @devices ||= fetch_clients
  end

  def print_devices
    devices.each do |c|
      puts "#{c.ip.rjust(10)} - #{c.mac} - #{c.hostname} (#{c.oui})"
    end
    puts "🖥  Found #{@devices.size} devices"
  end

  private

  def fetch_clients
    if ::FAKE_DATA
      json_clients = JSON.load(File.read(File.expand_path('../../devices.json', __FILE__)))["data"]
    else
      controller = Unifi::Controller.new(host: ENV['UNIFI_CONTROLLER_ADDRESS'])
      controller.login
      json_clients = controller.devices
    end
    @devices = json_clients.map { |c| OpenStruct.new(c) }
  end
end
