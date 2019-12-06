# Certs configurations for Apache
class kcerts::apache (
  $hostname             = $kcerts::node_fqdn,
  $cname                = $kcerts::cname,
  $generate             = $kcerts::generate,
  $regenerate           = $kcerts::regenerate,
  $deploy               = $kcerts::deploy,
  $pki_dir              = $kcerts::pki_dir,
  $server_cert          = $kcerts::server_cert,
  $server_key           = $kcerts::server_key,
  $server_cert_req      = $kcerts::server_cert_req,
  $country              = $kcerts::country,
  $state                = $kcerts::state,
  $city                 = $kcerts::city,
  $org                  = $kcerts::org,
  $org_unit             = $kcerts::org_unit,
  $expiration           = $kcerts::expiration,
  $default_ca           = $kcerts::default_ca,
  $ca_key_password_file = $kcerts::ca_key_password_file,
  $group                = $kcerts::group,
) inherits kcerts {

  $apache_cert_name = "${hostname}-apache"
  $apache_cert = "${pki_dir}/certs/katello-apache.crt"
  $apache_key  = "${pki_dir}/private/katello-apache.key"
  $apache_ca_cert = $kcerts::katello_server_ca_cert

  if $server_cert {
    cert { $apache_cert_name:
      ensure         => present,
      hostname       => $hostname,
      cname          => $cname,
      generate       => $generate,
      deploy         => $deploy,
      regenerate     => $regenerate,
      custom_pubkey  => $server_cert,
      custom_privkey => $server_key,
      custom_req     => $server_cert_req,
    }
  } else {
    cert { $apache_cert_name:
      ensure        => present,
      hostname      => $hostname,
      cname         => $cname,
      country       => $country,
      state         => $state,
      city          => $city,
      org           => $org,
      org_unit      => $org_unit,
      expiration    => $expiration,
      ca            => $default_ca,
      generate      => $generate,
      regenerate    => $regenerate,
      deploy        => $deploy,
      password_file => $ca_key_password_file,
    }
  }

  if $deploy {
    kcerts::keypair { 'apache':
      key_pair   => Cert[$apache_cert_name],
      key_file   => $apache_key,
      manage_key => true,
      key_owner  => 'root',
      key_group  => $group,
      key_mode   => '0440',
      cert_file  => $apache_cert,
    }
  }
}
