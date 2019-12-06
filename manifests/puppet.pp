# Class for handling Puppet cert configuration
class kcerts::puppet (
  $hostname             = $kcerts::node_fqdn,
  $cname                = $kcerts::cname,
  $generate             = $kcerts::generate,
  $regenerate           = $kcerts::regenerate,
  $deploy               = $kcerts::deploy,

  $client_cert          = $kcerts::puppet_client_cert,
  $client_key           = $kcerts::puppet_client_key,
  $ssl_ca_cert          = $kcerts::puppet_ssl_ca_cert,

  $country              = $kcerts::country,
  $state                = $kcerts::state,
  $city                 = $kcerts::city,
  $expiration           = $kcerts::expiration,
  $default_ca           = $kcerts::default_ca,
  $ca_key_password_file = $kcerts::ca_key_password_file,
  $server_ca            = $kcerts::server_ca,

  $pki_dir              = $kcerts::pki_dir,
) inherits kcerts {

  $puppet_client_cert_name = "${hostname}-puppet-client"

  # cert for authentication of puppetmaster against foreman
  cert { $puppet_client_cert_name:
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
    file { "${pki_dir}/puppet":
      ensure => directory,
      owner  => 'puppet',
      mode   => '0700',
    } ->
    kcerts::keypair { 'puppet':
      key_pair    => Cert[$puppet_client_cert_name],
      key_file    => $client_key,
      manage_key  => true,
      key_owner   => 'puppet',
      key_mode    => '0400',
      cert_file   => $client_cert,
      manage_cert => true,
      cert_owner  => 'puppet',
      cert_mode   => '0400',
    } ->
    pubkey { $ssl_ca_cert:
      key_pair => $server_ca,
    } ->
    file { $ssl_ca_cert:
      ensure => file,
      owner  => 'puppet',
      mode   => '0400',
    }
  }
}
