# Constains certs specific configurations for qpid dispatch router
class kcerts::qpid_router (
  $hostname               = $kcerts::node_fqdn,
  $cname                  = $kcerts::cname,
  $generate               = $kcerts::generate,
  $regenerate             = $kcerts::regenerate,
  $deploy                 = $kcerts::deploy,
  $server_cert            = $kcerts::qpid_router_server_cert,
  $client_cert            = $kcerts::qpid_router_client_cert,
  $server_key             = $kcerts::qpid_router_server_key,
  $client_key             = $kcerts::qpid_router_client_key,
  $owner                  = $kcerts::qpid_router_owner,
  $group                  = $kcerts::qpid_router_group,

  $country               = $kcerts::country,
  $state                 = $kcerts::state,
  $city                  = $kcerts::city,
  $org_unit              = $kcerts::org_unit,
  $expiration            = $kcerts::expiration,
  $default_ca            = $kcerts::default_ca,
  $ca_key_password_file  = $kcerts::ca_key_password_file,
) inherits kcerts {

  $server_keypair = "${hostname}-qpid-router-server"
  $client_keypair = "${hostname}-qpid-router-client"

  cert { $server_keypair:
    ensure        => present,
    hostname      => $hostname,
    cname         => $cname,
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'dispatch server',
    org_unit      => $org_unit,
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    purpose       => 'server',
    password_file => $ca_key_password_file,
  }

  cert { $client_keypair:
    ensure        => present,
    hostname      => $hostname,
    cname         => $cname,
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'dispatch client',
    org_unit      => $org_unit,
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    purpose       => 'client',
    password_file => $ca_key_password_file,
  }

  if $deploy {
    kcerts::keypair { 'qpid_router_server':
      key_pair    => Cert[$server_keypair],
      key_file    => $server_key,
      manage_key  => true,
      key_owner   => $owner,
      key_group   => $group,
      key_mode    => '0640',
      cert_file   => $server_cert,
      manage_cert => true,
      cert_owner  => $owner,
      cert_group  => $group,
      cert_mode   => '0640',
    }

    kcerts::keypair { 'qpid_router_client':
      key_pair    => Cert[$client_keypair],
      key_file    => $client_key,
      manage_key  => true,
      key_owner   => $owner,
      key_group   => $group,
      key_mode    => '0640',
      cert_file   => $client_cert,
      manage_cert => true,
      cert_owner  => $owner,
      cert_group  => $group,
      cert_mode   => '0640',
    }
  }
}
