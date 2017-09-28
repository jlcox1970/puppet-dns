define dns::dnssec::keys ($zone,$bind_dir,$urandom = false, $key_refresh = 12, $refresh_unit=h)
{
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
  $zsk_revoke = pick ($::bind_serials["$zone"]['dnssec_zsk_revoke'], undef)
  $ksk_revoke = pick ($::bind_serials["$zone"]['dnssec_ksk_revoke'], undef)

  # Get current EPOC time
  $epoc_time = inline_template("<%= Time.now.to_i %>")

  $zsk_remain = $zfs_revoke - $epoc_time
  $ksk_remain = $kfs_revoke - $epoc_time


  if $zsk_remain < $remaining_time {
    notify {"ZSK for zone $zone is aproaching expiry, generating new key":}
    exec {"dnssec-keygen $random -a RSASHA256 -b 2048 -3 $zone":
      cwd  => $bind_dir,
      path => '$PATH:/usr/sbin',
    }
  }

  if $ksk_remain < $remaining_time {
    notify {"KSK for zone $zone is aproaching expiry, generating new key":}
    exec {"dnssec-keygen $random -a RSASHA256 -b 2048 -3 -fk $zone":
      cwd  => $bind_dir,
      path => '$PATH:/usr/sbin',
    }
  }
}
