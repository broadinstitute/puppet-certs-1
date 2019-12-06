# Define: kcerts::tar_create
#
# This define creates a tar ball of generated SSL certs
#
# === Parameters
#
# $path::                       The $path of files to tar
#
# $foreman_proxy_fqdn::         FQDN of the foreman proxy
#
define kcerts::tar_create(
  $path               = $title,
  $foreman_proxy_fqdn = $kcerts::foreman_proxy_content::foreman_proxy_fqdn,
) {
  exec { "generate ${path}":
    cwd     => '/root',
    path    => ['/usr/bin', '/bin'],
    command => "tar -czf ${path} ssl-build/*.noarch.rpm ssl-build/${foreman_proxy_fqdn}/*.noarch.rpm",
  }
}
