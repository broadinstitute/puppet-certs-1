# Prepare the certificates for the node from the parent node
#
# === Parameters:
#
# $foreman_proxy_fqdn::             FQDN of the foreman proxy
#
# $foreman_proxy_cname::            additional names of the foreman proxy
#
# $kcerts_tar::                      Path to tar file with certs to generate
#
# === Advanced Parameters:
#
# $parent_fqdn::                    FQDN of the parent node. Does not usually
#                                   need to be set.
#
class kcerts::foreman_proxy_content (
  Stdlib::Fqdn $foreman_proxy_fqdn,
  Stdlib::Absolutepath $certs_tar,
  Stdlib::Fqdn $parent_fqdn = $kcerts::foreman_proxy_content::params::parent_fqdn,
  Array[Stdlib::Fqdn] $foreman_proxy_cname = $kcerts::foreman_proxy_content::params::foreman_proxy_cname,
) inherits kcerts::foreman_proxy_content::params {

  if $foreman_proxy_fqdn == $facts['fqdn'] {
    fail('The hostname is the same as the provided hostname for the foreman-proxy')
  }

  class { '::kcerts::puppet':        hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::foreman':       hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::foreman_proxy': hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::apache':        hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::qpid':          hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::qpid_router':   hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }
  class { '::kcerts::qpid_client':   hostname => $foreman_proxy_fqdn, cname => $foreman_proxy_cname }

  kcerts::tar_create { $certs_tar:
    subscribe => Class['kcerts::puppet', 'kcerts::foreman', 'kcerts::foreman_proxy', 'kcerts::qpid', 'kcerts::qpid_router', 'kcerts::apache', 'kcerts::qpid_client'],
  }
}
