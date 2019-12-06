# Handles Foreman Proxy cert configuration
class kcerts::foreman_proxy (
  $hostname             = $kcerts::node_fqdn,
  $cname                = $kcerts::cname,
  $generate             = $kcerts::generate,
  $regenerate           = $kcerts::regenerate,
  $deploy               = $kcerts::deploy,
  $proxy_cert           = $kcerts::params::foreman_proxy_cert,
  $proxy_key            = $kcerts::params::foreman_proxy_key,
  $proxy_ca_cert        = $kcerts::params::foreman_proxy_ca_cert,
  $foreman_ssl_cert     = $kcerts::params::foreman_proxy_foreman_ssl_cert,
  $foreman_ssl_key      = $kcerts::params::foreman_proxy_foreman_ssl_key,
  $foreman_ssl_ca_cert  = $kcerts::params::foreman_proxy_foreman_ssl_ca_cert,
  $pki_dir              = $kcerts::pki_dir,
  $server_ca            = $kcerts::server_ca,
  $server_cert          = $kcerts::server_cert,
  $server_key           = $kcerts::server_key,
  $server_cert_req      = $kcerts::server_cert_req,
  $country              = $kcerts::country,
  $state                = $kcerts::state,
  $city                 = $kcerts::city,
  $expiration           = $kcerts::expiration,
  $default_ca           = $kcerts::default_ca,
  $ca_key_password_file = $kcerts::ca_key_password_file,
  $group                = $kcerts::group,
) inherits kcerts {

  $proxy_cert_name = "${hostname}-foreman-proxy"
  $foreman_proxy_client_cert_name = "${hostname}-foreman-proxy-client"
  $foreman_proxy_ssl_client_bundle = "${pki_dir}/private/${foreman_proxy_client_cert_name}-bundle.pem"

  if $server_cert {
    cert { $proxy_cert_name:
      ensure         => present,
      hostname       => $hostname,
      cname          => $cname,
      generate       => $generate,
      regenerate     => $regenerate,
      deploy         => $deploy,
      custom_pubkey  => $server_cert,
      custom_privkey => $server_key,
      custom_req     => $server_cert_req,
    }
  } else {
    # cert for ssl of foreman-proxy
    cert { $proxy_cert_name:
      hostname      => $hostname,
      cname         => $cname,
      purpose       => 'server',
      country       => $country,
      state         => $state,
      city          => $city,
      org           => 'FOREMAN',
      org_unit      => 'SMART_PROXY',
      expiration    => $expiration,
      ca            => $default_ca,
      generate      => $generate,
      regenerate    => $regenerate,
      deploy        => $deploy,
      password_file => $ca_key_password_file,
    }
  }

  # cert for authentication of foreman_proxy against foreman
  cert { $foreman_proxy_client_cert_name:
    hostname      => $hostname,
    cname         => $cname,
    purpose       => 'client',
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'FOREMAN',
    org_unit      => 'FOREMAN_PROXY',
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  if $deploy {

    kcerts::keypair { 'foreman_proxy':
      key_pair   => Cert[$proxy_cert_name],
      key_file   => $proxy_key,
      manage_key => true,
      key_owner  => 'foreman-proxy',
      key_mode   => '0400',
      key_group  => $group,
      cert_file  => $proxy_cert,
    } ->
    pubkey { $proxy_ca_cert:
      key_pair => $default_ca,
    }

    kcerts::keypair { 'foreman_proxy_client':
      key_pair   => Cert[$foreman_proxy_client_cert_name],
      key_file   => $foreman_ssl_key,
      manage_key => true,
      key_owner  => 'foreman-proxy',
      key_mode   => '0400',
      cert_file  => $foreman_ssl_cert,
    } ->
    pubkey { $foreman_ssl_ca_cert:
      key_pair => $server_ca,
    } ~>
    key_bundle { $foreman_proxy_ssl_client_bundle:
      key_pair  => Cert[$foreman_proxy_client_cert_name],
      force_rsa => true,
    } ~>
    file { $foreman_proxy_ssl_client_bundle:
      ensure => file,
      mode   => '0644',
    }

  }
}
