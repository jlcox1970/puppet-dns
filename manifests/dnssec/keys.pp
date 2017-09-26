define dns::dnssec::keys ($zone,$bind_dir,$urandom = false)
{
  if ( $urandom == true ){
    $random = " -r /dev/urandom"
  }
  exec {"dnssec-keygen $random -a RSASHA256 -b 2048 -3 $zone":
    cwd      => $bind_dir,
    refreshonly =>  true
  }
}
