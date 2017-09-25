require 'facter'
begin
	kernel = Facter.value(:kernel)
	case kernel
	when /Linux/
		os = Facter.value(:osfamily)
		Facter.add(:bind_serials) do
			bind_serials = {}
			case os
			when /RedHat/
				all_zones = %x[ grep file /etc/named/named.conf.local  |cut -d\\\" -f2 ]
			when /Debian/
				all_zones = %x[ grep file /etc/bind/named.conf.local  |cut -d\\\" -f2 ]
			end
			all_zones.split("\n").each do |zone|
				serial_line = File.open(zone).grep(/Serial/)
				serial_split = serial_line[0].delete("\t").split(";")
				serial =serial_split[0]
				dnsdate = serial[0,8]
				dnsserial = serial[8,10]
				zone_split = zone.split("db.")
				zone_name = zone_split[1]

				_bind_serials = {}
				_bind_serials['zone_file'] = zone
				_bind_serials['serial'] = serial.to_i
				_bind_serials['dnsdate'] = dnsdate.to_i
				_bind_serials['dnsserial'] = dnsserial.to_i
				bind_serials[zone_name] = _bind_serials
			end
			setcode do
				bind_serials
			end
		end
	end

rescue []
end

