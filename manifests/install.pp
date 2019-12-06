# Certs Installation
class kcerts::install {

  package { 'katello-certs-tools':
    ensure  => installed,
  }

}
