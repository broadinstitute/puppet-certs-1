# == Class: kcerts
# Sets up the CA for Katello
class kcerts::ca (
  $default_ca_name         = $kcerts::default_ca_name,
  $server_ca_name          = $kcerts::server_ca_name,
  $ca_common_name          = $kcerts::ca_common_name,
  $country                 = $kcerts::country,
  $state                   = $kcerts::state,
  $city                    = $kcerts::city,
  $org                     = $kcerts::org,
  $org_unit                = $kcerts::org_unit,
  $ca_expiration           = $kcerts::ca_expiration,
  $generate                = $kcerts::generate,
  $deploy                  = $kcerts::deploy,
  $server_cert             = $kcerts::server_cert,
  $ssl_build_dir           = $kcerts::ssl_build_dir,
  $group                   = $kcerts::group,
  $katello_server_ca_cert  = $kcerts::katello_server_ca_cert,
  $ca_key                  = $kcerts::ca_key,
  $ca_cert                 = $kcerts::ca_cert,
  $ca_cert_stripped        = $kcerts::ca_cert_stripped,
  $ca_key_password         = $kcerts::ca_key_password,
  $ca_key_password_file    = $kcerts::ca_key_password_file,
) {

  file { $ca_key_password_file:
    ensure  => file,
    content => $ca_key_password,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
  } ~>
  ca { $default_ca_name:
    ensure        => present,
    common_name   => $ca_common_name,
    country       => $country,
    state         => $state,
    city          => $city,
    org           => $org,
    org_unit      => $org_unit,
    expiration    => $ca_expiration,
    generate      => $generate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }
  $default_ca = Ca[$default_ca_name]

  if $server_cert {
    ca { $server_ca_name:
      ensure        => present,
      generate      => $generate,
      deploy        => $deploy,
      custom_pubkey => $kcerts::server_ca_cert,
    }
  } else {
    ca { $server_ca_name:
      ensure   => present,
      generate => $generate,
      deploy   => $deploy,
      ca       => $default_ca,
    }
  }
  $server_ca = Ca[$server_ca_name]

  if $generate {
    file { "${ssl_build_dir}/KATELLO-TRUSTED-SSL-CERT":
      ensure  => link,
      target  => "${ssl_build_dir}/${server_ca_name}.crt",
      require => $server_ca,
    }
  }

  if $deploy {
    Ca[$default_ca_name] ~>
    pubkey { $ca_cert:
      key_pair => $default_ca,
    } ~>
    pubkey { $ca_cert_stripped:
      strip    => true,
      key_pair => $default_ca,
    } ~>
    file { $ca_cert:
      ensure => file,
      owner  => 'root',
      group  => $group,
      mode   => '0644',
    }

    Ca[$server_ca_name] ~>
    pubkey { $katello_server_ca_cert:
      key_pair => $server_ca,
    } ~>
    file { $katello_server_ca_cert:
      ensure => file,
      owner  => 'root',
      group  => $group,
      mode   => '0644',
    }

    if $generate {
      Ca[$default_ca_name] ~>
      privkey { $ca_key:
        key_pair      => $default_ca,
        unprotect     => true,
        password_file => $ca_key_password_file,
      } ~>
      file { $ca_key:
        ensure => file,
        owner  => 'root',
        group  => $group,
        mode   => '0440',
      }
    }
  }
}
