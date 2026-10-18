# Redmine Plugin Kit

This gem can be used for [Redmine](https://www.redmine.org/) Plugin for loading customizations.

In an ideal world, all plugins would use this gem as base. Or even better: this gem comes to Redmine core itself.

If you are a Redmine developer, feel free and offer PRs with your Improvements.

## Features

- Loader for plugin customizations
- Deface support for Redmine plugins
- Extension points: classes a plugin collects from all plugins, without a list naming them

## Why this gem?

1. a standard process for load patches, hooks or helper for plugins
2. deface is ready to use and does not require any additional plugin (e.g. redmine_base_deface). It is easier for a plugin user, to install one plugin (instead of two). This makes also sure, that all plugins uses the same deface version.

## Requirements

- Redmine `>= 7.0` (including upcoming)
- Ruby `>= 3.2` (only maintained ruby versions are supported)

## Installation

Add Gem to your Gemfile:

```ruby
gem 'redmine_plugin_kit'
```

## Extension points

A plugin (the host) can collect classes from all plugins, one file per class, e.g. widgets of `my_host`:

- every plugin keeps its classes in `lib/widgets/`; the host also has the module `lib/widgets.rb`, which makes it the host
- any other plugin declares the point in its `init.rb`. Zeitwerk then never eager loads its `lib/widgets/`, only `load!` of the host loads it, so without the host these files need no guard against a missing base class. They stay autoloadable: nothing outside `lib/widgets/` may refer to their constants, and `defined?(Widgets)` is no test for the host.

```ruby
loader = RedminePluginKit::Loader.new plugin_id: 'my_plugin'
loader.extends %w[widgets]

# a plugin without RedminePluginKit::Loader
RedminePluginKit::Extensions.declare __dir__, %w[widgets]
```

`classes` returns only what `load!` loaded, so read them at runtime, not in the setup of a plugin (the setups run in plugin order); `RedminePluginKit::Extensions.loaded? 'widgets'` tells whether `load!` ran.

An undeclared `lib/widgets/` stops the boot as long as the host is installed. Without it, a convention test of the plugin finds such a directory:

```ruby
assert_empty RedminePluginKit::Extensions.undeclared_dirs(plugin_dir, standalone: %w[searches])
```

`standalone` names the directories in `lib/` with classes but no module that belong to the plugin itself; a name without such a directory is an error.

The host loads and lists them:

```ruby
module Widgets
  class Base
    extend RedminePluginKit::Extensions::Abstract

    abstract!
  end
end

# in the setup of the host, which runs at boot and after every code reload
RedminePluginKit::Extensions.load! 'widgets'

# the loaded subclasses without abstract ones; with a key, a subclass with the
# same key replaces its superclass and two unrelated classes are an error
RedminePluginKit::Extensions.classes Widgets::Base, key: :widget_name
```

A file name used by several plugins stops the boot, as Zeitwerk would load only one of them.
