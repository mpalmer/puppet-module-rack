The Final, Ultimate Solution to Running Rack Applications.

What the hell is Rack, anyway?  Mighty fine question.  Rack is, at its core,
a way to wire together application server containers (like Unicorn, thin,
puma, rainbows, mongrel, webrick... the list goes on and on) and web
applications, in such a way that, in principle at least, you can run any web
application under any appserver, and it'll all Just Work.

Of course, in practice, things aren't quite that simple, but for now let's
just pretend that it is.

When would you use this module?  Any time someone wants to run a Ruby-based
web application, pretty much.  In theory, there may be Ruby webapps that
don't use Rack, but they'll be very few and far between.  The vast majority
of those will be creaky old pre Rails 3.0 apps, which this module can also
handle.  If someone comes to us with a weirdo webrick-only app... well, talk
to Womble then.  He'll sort 'em out.

For all of the gory details of how to use `rack::application` to assist you
in your plans for world domination, see the type's documentation.


# Client Instructions

The proper functioning of this method of running a Rack application depends
fairly heavily on the application itself being properly structured. 
Therefore, we have a standard set of guidelines for customers that should
cover all the eventualities:

    In order for your application to work best in our hosting environment,
    please keep the following hints in mind when deploying your application:
    
    * You should use [`bundler`](http://bundler.org) to specify the gems
      that your application needs.  If you need help writing a `Gemfile`,
      please let us know.
    
    * During the deployment process, you should run `bundle install
      --deployment` in the root of your application tree in order to have
      all your gems installed.
    
    * Your `Gemfile` should contain, at a minimum, the following gems:
      - `unicorn`
      - `rack`
    
    * You must provide a `config.ru` file that loads and starts your
      application; many frameworks (such as Rails) automatically provide
      one, however if you need help writing a custom `config.ru` file,
      please let us know.
    
    * We set `RACK_ENV` to `none` on all deployments; please ensure that all
      middleware you wish to use is configured in your `config.ru`.
    
    * If you require a specific version of Ruby to run your application,
      please let us know and we will make arrangements for that version to
      be made available.  If you require precise control over your Ruby
      version, and are happy to manage that requirement yourself, we can
      accommodate that also; please let us know if that is that case.
