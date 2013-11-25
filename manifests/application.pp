# There is only one type that you should ever have to use directly:
# `rack::application`.  It takes the following parameters:
# 
#  * `title` (string; *namevar*)
#
#     The name of the application.  It will be used
#     as the daemontools service name.
# 
#  * `user` (string; required)
#
#     The user to run the service as.
# 
#  * `rootdir` (string; required)
#
#     The base directory of the Rack application.  This is the directory
#     that should contain the `config.ru`, `Gemfile`, and `Gemfile.lock`
#     files.
# 
#  * `listen` (string; optional; default `"/etc/service/<name>/tmp/app.sock"`)
#
#     The socket or IP:port you wish Unicorn to listen on.  If the string
#     provided starts with a `/`, then it will taken as the absolute path to
#     a Unix socket; otherwise, it will be taken to be an IP address and
#     port (colon-separated) that Unicorn will listen on.
#   
#     Please note that if you don't like the default location, it is *your*
#     responsibility to ensure that Unicorn and the webserver can access the
#     location, or that the firewall is opened (if required) to allow IP
#     access.
# 
#  * `ruby_version` (string; optional; default `"system"`)
#
#     Which version of Ruby to use for the application.  This can be one of:
#   
#    * `"system"` -- Use the system's own installation of Ruby.  This is
#      pretty much guaranteed to be an older release of Ruby, but on the
#      upside it'll probably get automated security patches and all that
#      that implies.
#
#    * `"application"` -- Read the version of Ruby required from a file
#      called `.ruby-version` in the root of the application tree.  Note
#      that this will potentially install a version of Ruby *at application
#      start*, so there may be a significant delay the first time a new
#      version of Ruby is requested.
#
#    * Any other string is taken to be a Ruby version specifier, as
#      understood by
#      [`ruby-build`](https://github.com/anchor/ruby-build#readme).  To get
#      the list of available Ruby versions for a given machine, run
#      `ruby-build --definitions`.
# 
#  * `concurrency` (integer; optional; default `1`)
#
#     The number of Unicorn workers to run for the application.  Each worker
#     can handle a single request at a time.
# 
#  * `environment` (hash; optional; default `{}`)
#
#     A hash of `VAR => value` pairs, listing variables to set in the
#     application environment.
# 
#  * `old_rails_hacks` (boolean; optional; default `false`)
#
#     Rails versions prior to 3.0 didn't support Rack; instead, they used
#     their own crazy scheme.  Unicorn does support said crazy scheme,
#     though, so if you're running an app on a shit-old version of Rails,
#     feel free to set this parameter to `true` to get all the dodgy-rails
#     goodness.
#
define rack::application(
	$user,
	$rootdir,
	$listen          = false,
	$ruby_version    = "system",
	$concurrency     = 1,
	$old_rails_hacks = false,
	$environment     = {}
) {
	include rack::unicorn_daemontools_wrapper
	
	if $listen {
		$listen_opt = "-l $listen"
	} else {
		$listen_opt = "-l /etc/service/${name}/tmp/app.sock"
	}
	
	file {
		"/etc/service/${name}/tmp":
			ensure  => directory,
			mode    => 0710,
			owner   => $user,
			group   => "www-data",
			require => Daemontools::Service[$name]
	}
	
	case $ruby_version {
		"system": {
			$use_ruby_version = ""
		}
		"application": {
			include ruby_build::base
			$use_ruby_version = "chruby"  # chruby will work out what to do based on .ruby-version
		}
		default: {
			ruby_build::install { "rack::application/$name":
				definition => $ruby_version
			}
			
			$use_ruby_version = "chruby ${ruby_version}"
		}
	}
	
	if $old_rails_hacks {
		$unicorn = "unicorn_rails"
	} else {
		$unicorn = "unicorn"
	}
	
	daemontools::service { $name:
		command     => "bundle exec unicorn-daemontools-wrapper $unicorn -E none $listen_opt",
		user        => $user,
		control     => "allah",
		directory   => $rootdir,
		environment => $environment,
		pre_command => $use_ruby_version,
	}
}
