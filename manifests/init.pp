# == Class: kcerts
#
# Base for installing and configuring certs. It holds the basic configuration
# aournd certificates generation and deployment. The per-subsystem configuratoin
# of certificates should go into `subsystem_module/manifests/certs.pp`.
#
# === Parameters:
#
# $node_fqdn::            The fqdn of the host the generated certificates
#                         should be for
#
# $cname::                The alternative names of the host the generated certificates
#                         should be for
#
# $server_ca_cert::       Path to the CA that issued the ssl certificates for https
#                         if not specified, the default CA will be used
#
# $server_cert::          Path to the ssl certificate for https
#                         if not specified, the default CA will generate one
#
# $server_key::           Path to the ssl key for https
#                         if not specified, the default CA will generate one
#
# $server_cert_req::      Path to the ssl certificate request for https
#                         if not specified, the default CA will generate one
#
# $tar_file::             Use a tarball with certificates rather than generate
#                         new ones. This can be used on another node which is
#                         not the CA.
#
# === Advanced parameters:
#
# $log_dir::              Where the log files should go
#
# $generate::             Should the generation of the certs be part of the
#                         configuration
#
# $regenerate::           Force regeneration of the certificates (excluding
#                         CA certificates)
#
# $regenerate_ca::        Force regeneration of the CA certificate
#
# $deploy::               Deploy the certs on the configured system. False means
#                         we want to apply it to a different system
#
# $ca_common_name::       Common name for the generated CA certificate
#
# $country::              Country attribute for managed certificates
#
# $state::                State attribute for managed certificates
#
# $city::                 City attribute for managed certificates
#
# $org::                  Org attribute for managed certificates
#
# $org_unit::             Org unit attribute for managed certificates
#
# $expiration::           Expiration attribute for managed certificates
#
# $ca_expiration::        CA expiration attribute for managed certificates
#
# $pki_dir::              The PKI directory under which to place certs
#
# $ssl_build_dir::        The directory where SSL keys, certs and RPMs will be generated
#
# $user::                 The system user name who should own the certs
#
# $group::                The group who should own the certs
#
# $default_ca_name::      The name of the default CA
#
# $server_ca_name::       The name of the server CA (used for https)
#
class kcerts (
  Stdlib::Absolutepath $log_dir = $kcerts::params::log_dir,
  Stdlib::Fqdn $node_fqdn = $kcerts::params::node_fqdn,
  Array[Stdlib::Fqdn] $cname = $kcerts::params::cname,
  Boolean $generate = $kcerts::params::generate,
  Boolean $regenerate = $kcerts::params::regenerate,
  Boolean $regenerate_ca = $kcerts::params::regenerate_ca,
  Boolean $deploy = $kcerts::params::deploy,
  String $ca_common_name = $kcerts::params::ca_common_name,
  String[2,2] $country = $kcerts::params::country,
  String $state = $kcerts::params::state,
  String $city = $kcerts::params::city,
  String $org = $kcerts::params::org,
  String $org_unit = $kcerts::params::org_unit,
  String $expiration = $kcerts::params::expiration,
  String $ca_expiration = $kcerts::params::ca_expiration,
  Optional[Stdlib::Absolutepath] $server_cert = $kcerts::params::server_cert,
  Optional[Stdlib::Absolutepath] $server_key = $kcerts::params::server_key,
  Optional[Stdlib::Absolutepath] $server_cert_req = $kcerts::params::server_cert_req,
  Optional[Stdlib::Absolutepath] $server_ca_cert = $kcerts::params::server_ca_cert,
  Stdlib::Absolutepath $pki_dir = $kcerts::params::pki_dir,
  Stdlib::Absolutepath $ssl_build_dir = $kcerts::params::ssl_build_dir,
  String $user = $kcerts::params::user,
  String $group = $kcerts::params::group,
  String $default_ca_name = $kcerts::params::default_ca_name,
  String $server_ca_name = $kcerts::params::server_ca_name,
  Optional[Stdlib::Absolutepath] $tar_file = $kcerts::params::tar_file,
) inherits kcerts::params {

  if $server_cert {
    validate_file_exists($server_cert, $server_key, $server_ca_cert)
    if $server_cert_req {
      validate_file_exists($server_cert_req)
    }
  }

  $nss_db_dir   = "${pki_dir}/nssdb"

  $ca_key = "${pki_dir}/private/${default_ca_name}.key"
  $ca_cert = "${pki_dir}/certs/${default_ca_name}.crt"
  $ca_cert_stripped = "${pki_dir}/certs/${default_ca_name}-stripped.crt"
  $ca_key_password = extlib::cache_data('foreman_cache_data', 'ca_key_password', extlib::random_password(24))
  $ca_key_password_file = "${pki_dir}/private/${default_ca_name}.pwd"

  $katello_server_ca_cert = "${pki_dir}/certs/${server_ca_name}.crt"
  $katello_default_ca_cert = "${pki_dir}/certs/${default_ca_name}.crt"

  if $tar_file {
    kcerts::tar_extract { $tar_file:
      before => Class['kcerts::install'],
    }
  }

  contain kcerts::install
  contain kcerts::config
  contain kcerts::ca

  Class['kcerts::install'] ->
  Class['kcerts::config'] ->
  Class['kcerts::ca']

  $default_ca = $kcerts::ca::default_ca
  $server_ca = $kcerts::ca::server_ca
}
