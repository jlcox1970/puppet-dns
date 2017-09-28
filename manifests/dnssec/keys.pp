define dns::dnssec::keys ($zone,$bind_dir,$urandom = false, $key_refresh = 12, $refresh_unit=h, $ensure = absent)
{
  case $ensure {

    /^purged/:{
      file { "${bind_dir}/K${zone}*":
        ensure =>  absent
      }
      default : {
        if ( $urandom == true ){
          $random = " -r /dev/urandom"
        }
        case $refresh_unit {
          /^h|H/:{
            $multiplier = 3600
          }
          /^m|M/:{
            $multiplier = 3600 * 24 * 30
          }
          /^d|D/ : {
          $multiplier = 3600 * 24
        }
        default: {
          fail(" Unknown units for dns::dnssec::keys::refresh_units $refresh_units , Please select [H]ours, [D]ays or [M]onths" )
        }
      }
      $remaining_time =  $multiplier * $key_refresh

      # Get the exisiting ket revoke time
      $zsk_revoke_fact  = $::bind_serials["$zone"]['dnssec_zsk_revoke']
      $ksk_revoke_fact  = $::bind_serials["$zone"]['dnssec_ksk_revoke']
      $zsk_current_key  = $::bind_serials["$zone"]['dnssec_zsk_file']
      $ksk_current_key  = $::bind_serials["$zone"]['dnssec_ksk_file']
      $zsk_revoke = inline_template("<%= @zsk_revoke_fact.to_i %>")
      $ksk_revoke = inline_template("<%= @ksk_revoke_fact.to_i %>")



      # Get current EPOC time
      $epoc_time = inline_template("<%= Time.now.to_i %>")

      $zsk_remain = $zsk_revoke - $epoc_time
      $ksk_remain = $ksk_revoke - $epoc_time

      if $zsk_current_key != undef {
        $zsk_successor = " -S $zsk_current_key "
      } else {
        $zsk_successor = '-a RSASHA256 -b 2048 -3'
      }
      if $ksk_current_key != undef {
        $ksk_successor = " -S $ksk_current_key "
      } else {
        $ksk_successor = '-a RSASHA256 -b 2048 -3'
      }
      if $zsk_remain < $remaining_time {
        exec {"Building DNSSEC ZSK for $zone":
          command => "dnssec-keygen -R +1mo -I +2mo -D +3mo $zsk_successor $random  $zone ",
          cwd     => $bind_dir,
          path    => '$PATH:/usr/sbin',
          user    => $dns::server::params::owner,
          group   => $dns::server::params::group,

        }
      }

      if $ksk_remain < $remaining_time {
        exec {"Building DNSSEC KSK for $zone":
          command => "dnssec-keygen -R +1y -I +2y -D +3y $ksk_successor $random  -fk $zone",
          cwd     => $bind_dir,
          path    => '$PATH:/usr/sbin',
          user    => $dns::server::params::owner,
          group   => $dns::server::params::group,
        }
      }
    }
  }
