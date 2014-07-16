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
#  * `allah_group` (string; optional; default `undef`)
#
#     Nominate an allah group to make this rack application's daemontools
#     service a part of.
#
define rack::application(
	$user,
	$rootdir,
	$listen          = false,
	$ruby_version    = "system",
	$concurrency     = 1,
	$old_rails_hacks = false,
	$environment     = {},
	$allah_group     = undef
) {
	include rack::unicorn_daemontools_wrapper
	include chruby::install

	if $listen {
		$listen_opt = "-l $listen"
	} else {
		$listen_opt = "-l /etc/service/${name}/tmp/app.sock"
	}

	$rack_application_workers = $concurrency

	file {
		"/etc/service/${name}/tmp":
			ensure  => directory,
			mode    => 0710,
			owner   => $user,
			group   => "www-data";
		"/etc/service/${name}/unicorn.conf":
			ensure  => file,
			content => template("rack/unicorn.conf"),
			mode    => 0440,
			owner   => $user,
			notify  => Exec["daemontools/service/refresh:${name}"];
	}

	$rubies_path = {"RUBIES_PATH" => "/usr/local/lib/rubies"}

	case $ruby_version {
		"system": {
			$ruby_version_spec = "system"
			$full_environment  = $environment
		}
		"application": {
			include ruby_build::base
			$quoted_ruby_version_file = shellquote("${rootdir}/.ruby-version")
			$ruby_version_spec = "\"$(cat ${quoted_ruby_version_file})\""

			$pre_commands = [
				"ruby-build-wrapper ${ruby_version_spec}",
			]
			$full_environment = merge($environment, $rubies_path)
		}
		default: {
			ruby_build::install { "rack::application/$name":
				definition => $ruby_version
			}

			$ruby_version_spec = $ruby_version
			$full_environment = merge($environment, $rubies_path)
		}
	}

	if $old_rails_hacks {
		$unicorn = "unicorn_rails"
	} else {
		$unicorn = "unicorn"
	}

	daemontools::service { $name:
		command      => "chruby-exec ${ruby_version_spec} -- exec bundle exec unicorn-daemontools-wrapper $unicorn -E none $listen_opt -c /etc/service/${name}/unicorn.conf",
		user         => $user,
		sudo_control => "allah",
		directory    => $rootdir,
		environment  => $full_environment,
		pre_command  => $pre_commands,
		allah_group  => $allah_group,
	}
}
