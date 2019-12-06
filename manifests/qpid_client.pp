# Pulp Master Certs configuration
class kcerts::qpid_client (
  $hostname              = $kcerts::node_fqdn,
  $cname                 = $kcerts::cname,
  $generate              = $kcerts::generate,
  $regenerate            = $kcerts::regenerate,
  $deploy                = $kcerts::deploy,

  $qpid_client_cert      = $kcerts::qpid_client_cert,
  $qpid_client_ca_cert   = $kcerts::qpid_client_ca_cert,

  $country               = $kcerts::country,
  $state                 = $kcerts::state,
  $city                  = $kcerts::city,
  $org_unit              = $kcerts::org_unit,
  $expiration            = $kcerts::expiration,
  $default_ca            = $kcerts::default_ca,
  $ca_key_password_file  = $kcerts::ca_key_password_file,

  $cert_group            = 'apache',
) inherits kcerts {

  $qpid_client_cert_name = "${hostname}-qpid-client-cert"

  cert { $qpid_client_cert_name:
    hostname      => $hostname,
    cname         => $cname,
    common_name   => 'pulp-qpid-client-cert',
    purpose       => client,
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'PULP',
    org_unit      => $org_unit,
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  if $deploy {

    file { $kcerts::pulp_pki_dir:
      ensure => directory,
      owner  => 'root',
      group  => $cert_group,
      mode   => '0640',
    }

    file { "${kcerts::pulp_pki_dir}/qpid":
      ensure => directory,
      owner  => 'root',
      group  => $cert_group,
      mode   => '0640',
    } ~>
    Cert[$qpid_client_cert_name] ~>
    key_bundle { $qpid_client_cert:
      key_pair => Cert[$qpid_client_cert_name],
    } ~>
    file { $qpid_client_cert:
      owner => 'root',
      group => $cert_group,
      mode  => '0640',
    } ~>
    pubkey { $qpid_client_ca_cert:
      key_pair => $default_ca,
    }
  }

}
