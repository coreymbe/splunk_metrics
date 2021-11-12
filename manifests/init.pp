# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include splunk_metrics
class splunk_metrics (
  String $url,
  String $token,
  String $pe_console = 'puppet_support_script',
){

  # Account for the differences in running on Primary Server or Agent Node
  if $facts[pe_server_version] != undef {
    $owner = 'pe-puppet'
    $group = 'pe-puppet'
  }
  else {
    $owner = 'root'
    $group = 'root'
  }

  file { "${settings::confdir}/splunk_metrics":
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { "${settings::confdir}/splunk_metrics/splunk_metrics.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    require => File["${settings::confdir}/splunk_metrics"],
    content => epp('splunk_metrics/splunk_metrics.yaml'),
  }

  file { "${settings::confdir}/splunk_metrics/post_metrics.sh":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File["${settings::confdir}/splunk_metrics"],
    source  => 'puppet:///modules/splunk_metrics/post_metrics.sh',
  }
}
