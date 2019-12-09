# Constains certs specific configurations for candlepin
class kcerts::candlepin (
  $hostname               = $kcerts::node_fqdn,
  $cname                  = $kcerts::cname,
  $generate               = $kcerts::generate,
  $regenerate             = $kcerts::regenerate,
  $deploy                 = $kcerts::deploy,
  $ca_cert                = $kcerts::candlepin_ca_cert,
  $ca_key                 = $kcerts::candlepin_ca_key,
  $pki_dir                = $kcerts::pki_dir,
  $keystore               = $kcerts::candlepin_keystore,
  $keystore_password      = extlib::cache_data('foreman_cache_data', $keystore_password, extlib::random_password(32))
  $keystore_password_file = $kcerts::keystore_password_file,
  $amqp_truststore        = $kcerts::candlepin_amqp_truststore,
  $amqp_keystore          = $kcerts::candlepin_amqp_keystore,
  $amqp_store_dir         = $kcerts::candlepin_amqp_store_dir,
  $country                = $kcerts::country,
  $state                  = $kcerts::state,
  $city                   = $kcerts::city,
  $org                    = $kcerts::org,
  $org_unit               = $kcerts::org_unit,
  $expiration             = $kcerts::expiration,
  $default_ca             = $kcerts::default_ca,
  $ca_key_password_file   = $kcerts::ca_key_password_file,
  $user                   = $kcerts::user,
  $group                  = $kcerts::group,
) inherits kcerts {

  Exec {
    logoutput => 'on_failure',
    path      => ['/bin/', '/usr/bin'],
  }

  $java_client_cert_name = 'java-client'

  cert { $java_client_cert_name:
    ensure        => present,
    hostname      => $hostname,
    cname         => $cname,
    country       => $country,
    state         => $state,
    city          => $city,
    org           => 'candlepin',
    org_unit      => $org_unit,
    expiration    => $expiration,
    ca            => $default_ca,
    generate      => $generate,
    regenerate    => $regenerate,
    deploy        => $deploy,
    password_file => $ca_key_password_file,
  }

  $tomcat_cert_name = "${hostname}-tomcat"
  $tomcat_cert = "${pki_dir}/certs/katello-tomcat.crt"
  $tomcat_key  = "${pki_dir}/private/katello-tomcat.key"

  cert { $tomcat_cert_name:
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

  $password_file = "${pki_dir}/keystore_password-file"
  $client_req = "${pki_dir}/java-client.req"
  $client_cert = "${pki_dir}/certs/${java_client_cert_name}.crt"
  $client_key = "${pki_dir}/private/${java_client_cert_name}.key"
  $alias = 'candlepin-ca'

  if $deploy {
    kcerts::keypair { 'candlepin-ca':
      manage_cert   => true,
      manage_key    => true,
      key_pair      => $default_ca,
      key_file      => $ca_key,
      cert_file     => $ca_cert,
      cert_owner    => 'tomcat',
      cert_group    => 'tomcat',
      key_owner     => 'tomcat',
      key_group     => 'tomcat',
      key_mode      => '0440',
      cert_mode     => '0640',
      unprotect     => true,
      strip         => true,
      password_file => $ca_key_password_file,
    } ~>
    kcerts::keypair { 'tomcat':
      key_pair  => Cert[$tomcat_cert_name],
      key_file  => $tomcat_key,
      cert_file => $tomcat_cert,
    } ~>
    file { $password_file:
      ensure  => file,
      content => $keystore_password,
      owner   => $user,
      group   => $group,
      mode    => '0440',
    } ~>
    exec { 'candlepin-generate-ssl-keystore':
      command => "openssl pkcs12 -export -in ${tomcat_cert} -inkey ${tomcat_key} -out ${keystore} -name tomcat -CAfile ${ca_cert} -caname root -password \"file:${password_file}\" -passin \"file:${ca_key_password_file}\" ",
      creates => $keystore,
    } ~>
    file { $keystore:
      ensure => file,
      owner  => 'tomcat',
      group  => $group,
      mode   => '0640',
    } ~>
    kcerts::keypair { 'candlepin':
      key_pair  => Cert[$java_client_cert_name],
      key_file  => $client_key,
      cert_file => $client_cert,
    } ~>
    file { $amqp_store_dir:
      ensure => directory,
      owner  => 'tomcat',
      group  => $group,
      mode   => '0750',
    } ~>
    exec { 'import CA into Candlepin truststore':
      command => "keytool -import -trustcacerts -v -keystore ${keystore} -storepass ${keystore_password} -alias ${alias} -file ${ca_cert} -noprompt",
      unless  => "keytool -list -keystore ${keystore} -storepass ${keystore_password} -alias ${alias}",
    } ~>
    exec { 'import CA into Candlepin AMQP truststore':
      command => "keytool -import -v -keystore ${amqp_truststore} -storepass ${keystore_password} -alias ${alias} -file ${ca_cert} -trustcacerts -noprompt",
      unless  => "keytool -list -keystore ${amqp_truststore} -storepass ${keystore_password} -alias ${alias}",
    } ~>
    exec { 'import client certificate into Candlepin keystore':
      # Stupid keytool doesn't allow you to import a keypair.  You can only import a cert.  Hence, we have to
      # create the store as an PKCS12 and convert to JKS.  See http://stackoverflow.com/a/8224863
      command => "openssl pkcs12 -export -name amqp-client -in ${client_cert} -inkey ${client_key} -out /tmp/keystore.p12 -passout file:${password_file} && keytool -importkeystore -destkeystore ${amqp_keystore} -srckeystore /tmp/keystore.p12 -srcstoretype pkcs12 -alias amqp-client -storepass ${keystore_password} -srcstorepass ${keystore_password} -noprompt && rm /tmp/keystore.p12",
      unless  => "keytool -list -keystore ${amqp_keystore} -storepass ${keystore_password} -alias amqp-client",
    } ~>
    file { $amqp_keystore:
      ensure => file,
      owner  => 'tomcat',
      group  => $group,
      mode   => '0640',
    }
  }
}
