class rack::unicorn_daemontools_wrapper {
	file { "/usr/local/bin/unicorn-daemontools-wrapper":
		ensure => file,
		source => "puppet:///modules/rack/usr/local/bin/unicorn-daemontools-wrapper",
		mode   => 0444,
		owner  => "root",
		group  => "root";
	}
}
