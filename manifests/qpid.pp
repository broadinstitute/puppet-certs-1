# Handles Qpid cert configuration
class kcerts::qpid (
  $hostname             = $kcerts::node_fqdn,
  $cname                = $kcerts::cname,
  $generate             = $kcerts::generate,
  $regenerate           = $kcerts::regenerate,
  $deploy               = $kcerts::deploy,
  $country              = $kcerts::country,
  $state                = $kcerts::state,
  $city                 = $kcerts::city,
  $org_unit             = $kcerts::org_unit,
  $expiration           = $kcerts::expiration,
  $default_ca           = $kcerts::default_ca,
  $ca_key_password_file = $kcerts::ca_key_password_file,
  $pki_dir              = $kcerts::pki_dir,
  $ca_cert              = $kcerts::ca_cert,
  $qpidd_group          = $kcerts::qpidd_group,
  $nss_cert_name        = 'broker',
) inherits kcerts {

  Exec { logoutput => 'on_failure' }

  $qpid_cert_name = "${hostname}-qpid-broker"

  cert { $qpid_cert_name:
    ensure        => present,
    hostname      => $hostname,
    cname         => concat($cname, 'localhost'),
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'pulp',
    org_unit      => $org_unit,
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  if $deploy {
    include kcerts::ssltools::nssdb
    $nss_db_dir = $kcerts::ssltools::nssdb::nss_db_dir
    $nss_db_password_file = $kcerts::ssltools::nssdb::nss_db_password_file

    $client_cert            = "${pki_dir}/certs/${qpid_cert_name}.crt"
    $client_key             = "${pki_dir}/private/${qpid_cert_name}.key"
    $pfx_path               = "${pki_dir}/${qpid_cert_name}.pfx"

    kcerts::keypair { 'qpid':
      key_pair   => Cert[$qpid_cert_name],
      key_file   => $client_key,
      manage_key => true,
      key_owner  => 'root',
      key_group  => $qpidd_group,
      key_mode   => '0440',
      cert_file  => $client_cert,
    } ~>
    Class['::kcerts::ssltools::nssdb'] ~>
    kcerts::ssltools::certutil { 'ca':
      nss_db_dir  => $nss_db_dir,
      client_cert => $ca_cert,
      trustargs   => 'TCu,Cu,Tuw',
      refreshonly => true,
      subscribe   => Pubkey[$ca_cert],
    } ~>
    kcerts::ssltools::certutil { $nss_cert_name:
      nss_db_dir  => $nss_db_dir,
      client_cert => $client_cert,
      refreshonly => true,
      subscribe   => Pubkey[$client_cert],
    } ~>
    exec { 'generate-pfx-for-nss-db':
      command     => "openssl pkcs12 -in ${client_cert} -inkey ${client_key} -export -out '${pfx_path}' -password 'file:${nss_db_password_file}' -name '${nss_cert_name}'",
      path        => '/usr/bin',
      refreshonly => true,
    } ~>
    exec { 'add-private-key-to-nss-db':
      command     => "pk12util -i '${pfx_path}' -d '${nss_db_dir}' -w '${nss_db_password_file}' -k '${nss_db_password_file}'",
      path        => '/usr/bin',
      refreshonly => true,
    }
  }
}
