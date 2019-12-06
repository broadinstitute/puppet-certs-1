# Pulp Client Certs
class kcerts::pulp_client (
  $hostname    = $kcerts::node_fqdn,
  $cname       = $kcerts::cname,
  $generate    = $kcerts::generate,
  $regenerate  = $kcerts::regenerate,
  $deploy      = $kcerts::deploy,
  $common_name = 'admin',
  $pki_dir      = $kcerts::pki_dir,
  $ca_cert      = $kcerts::ca_cert,
  $country                 = $kcerts::country,
  $state                   = $kcerts::state,
  $city                    = $kcerts::city,
  $expiration           = $kcerts::expiration,
  $default_ca           = $kcerts::default_ca,
  $ca_key_password_file    = $kcerts::ca_key_password_file,
  $group                   = $kcerts::group,
) inherits kcerts {

  $client_cert_name = 'pulp-client'
  $client_cert      = "${pki_dir}/certs/${client_cert_name}.crt"
  $client_key       = "${pki_dir}/private/${client_cert_name}.key"
  $ssl_ca_cert      = $ca_cert

  cert { $client_cert_name:
    hostname      => $hostname,
    cname         => $cname,
    common_name   => $common_name,
    purpose       => client,
    country       => $kcerts::country,
    state         => $kcerts::state,
    city          => $kcerts::city,
    org           => 'PULP',
    org_unit      => 'NODES',
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  if $deploy {
    kcerts::keypair { 'pulp_client':
      key_pair   => Cert[$client_cert_name],
      key_file   => $client_key,
      manage_key => true,
      key_group  => $group,
      key_owner  => 'root',
      key_mode   => '0440',
      cert_file  => $client_cert,
    }
  }
}
