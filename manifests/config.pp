# Certs Configuration
class kcerts::config (
  $pki_dir = $kcerts::pki_dir,
  $group   = $kcerts::group,
) {

  file { $pki_dir:
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  file { "${pki_dir}/certs":
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0755',
  }

  file { "${pki_dir}/private":
    ensure => directory,
    owner  => 'root',
    group  => $group,
    mode   => '0750',
  }

}
