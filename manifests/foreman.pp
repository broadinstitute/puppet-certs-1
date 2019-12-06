# Handles Foreman certs configuration
class kcerts::foreman (
  $hostname              = $kcerts::node_fqdn,
  $cname                 = $kcerts::cname,
  $generate              = $kcerts::generate,
  $regenerate            = $kcerts::regenerate,
  $deploy                = $kcerts::deploy,
  $client_cert           = $kcerts::params::foreman_client_cert,
  $client_key            = $kcerts::params::foreman_client_key,
  $ssl_ca_cert           = $kcerts::params::foreman_ssl_ca_cert,
  $country               = $kcerts::country,
  $state                 = $kcerts::state,
  $city                  = $kcerts::city,
  $expiration            = $kcerts::expiration,
  $default_ca            = $kcerts::default_ca,
  $ca_key_password_file  = $kcerts::ca_key_password_file,
  $server_ca             = $kcerts::server_ca,
) inherits kcerts::params {

  $client_cert_name = "${hostname}-foreman-client"

  # cert for authentication of puppetmaster against foreman
  cert { $client_cert_name:
    hostname      => $hostname,
    cname         => $cname,
    purpose       => 'client',
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'FOREMAN',
    org_unit      => 'PUPPET',
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  if $deploy {
    kcerts::keypair { 'foreman':
      key_pair   => Cert[$client_cert_name],
      key_file   => $client_key,
      manage_key => true,
      key_owner  => 'foreman',
      key_mode   => '0400',
      cert_file  => $client_cert,
    } ->
    pubkey { $ssl_ca_cert:
      key_pair => $server_ca,
    }
  }
}
