require 'facter'
kernel = Facter.value(:kernel)
case kernel
when /Linux/
        os = Facter.value(:osfamily)
        begin
                Facter.add(:bind_serials) do
                        bind_serials = {}
                        case os
                        when /RedHat/
                                all_zones = %x[ grep file /etc/named/named.conf.local  |cut -d\\\" -f2 ]
                                bind_dir ="/var/named"
                        when /Debian/
                                all_zones = %x[ grep file /etc/bind/named.conf.local  |cut -d\\\" -f2 ]
                                bind_dir ="/var/bind"
                        end
                        all_zones.split("\n").each do |zone|
                                serial_line = File.open(zone).grep(/Serial/)
                                serial_split = serial_line[0].delete("\t").split(";")
                                serial =serial_split[0]
                                dnsdate = serial[0,8]
                                dnsserial = serial[8,10]
                                zone_split = zone.split("db.")
                                zone_name = zone_split[1]

                                # Work out the dnssec key info
                                #ZSK 256
                                #KSK 257

                                zsk_current_created = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p C $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                zsk_current_publish = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p P $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                zsk_current_activate = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`;do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p A $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                zsk_current_revoke = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do  grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p R $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                zsk_current_inactive = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`;do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p I $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                zsk_current_delete = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do  grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p D $i; done |grep 256 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_created = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p C $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_publish = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p P $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_activate = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`;do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p A $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_revoke = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do  grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p R $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_inactive = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`;do grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p I $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]
                                ksk_current_delete = %x[ for i in `ls #{bind_dir}/K#{zone_name}*key`; do  grep DNSKEY $i | awk '{printf $4" "}' ;dnssec-settime -u -p D $i; done |grep 257 |grep -v UNSET |awk '{print $3}'|sort |tail -n 1 ]

                                _bind_serials = {}
                                _bind_serials['zone_file'] = zone
                                _bind_serials['serial'] = serial.to_i
                                _bind_serials['dnsdate'] = dnsdate.to_i
                                _bind_serials['dnsserial'] = dnsserial.to_i
                                _bind_serials['dnssec_zsk_created'] = zsk_current_created.delete("\n").to_i
                                _bind_serials['dnssec_zsk_publish'] = zsk_current_publish.delete("\n").to_i
                                _bind_serials['dnssec_zsk_activate'] = zsk_current_activate.delete("\n").to_i
                                _bind_serials['dnssec_zsk_revoke'] = zsk_current_revoke.delete("\n").to_i
                                _bind_serials['dnssec_zsk_inactive'] = zsk_current_inactive.delete("\n").to_i
                                _bind_serials['dnssec_zsk_delete'] = zsk_current_delete.delete("\n").to_i
                                _bind_serials['dnssec_ksk_created'] = ksk_current_created.delete("\n").to_i
                                _bind_serials['dnssec_ksk_publish'] = ksk_current_publish.delete("\n").to_i
                                _bind_serials['dnssec_ksk_activate'] = ksk_current_activate.delete("\n").to_i
                                _bind_serials['dnssec_ksk_revoke'] = ksk_current_revoke.delete("\n").to_i
                                _bind_serials['dnssec_ksk_inactive'] = ksk_current_inactive.delete("\n").to_i
                                _bind_serials['dnssec_ksk_delete'] = ksk_current_delete.delete("\n").to_i
                                bind_serials[zone_name] = _bind_serials
                        end
                        setcode do
                                bind_serials
                        end
                end
        rescue
                Facter.add(:bind_serials) do
                        bind_serials = {}
                        case os
                        when /RedHat/
                                all_zones = %x[ grep file /etc/named/named.conf.local  |cut -d\\\" -f2 ]
                        when /Debian/
                                all_zones = %x[ grep file /etc/bind/named.conf.local  |cut -d\\\" -f2 ]
                        end
                        all_zones.split("\n").each do |zone|
                                zone_split = zone.split("db.")
                                zone_name = zone_split[1]

                                _bind_serials = {}
                                _bind_serials['zone_file'] = zone
                                _bind_serials['serial'] = 0
                                _bind_serials['dnsdate'] = 0
                                _bind_serials['dnsserial'] = 0
                                bind_serials[zone_name] = _bind_serials
                        end
                        setcode do
                                bind_serials
                        end
                end
        end
end

