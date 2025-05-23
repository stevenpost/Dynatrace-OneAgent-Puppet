# Changelog

All notable changes to this project will be documented in this file.

## Release 2.0.0

**Warning:** breaking API changes

### Features

- Overhaul of the module
- Support for `discovery` mode
- Signature verification by default

### Bugfixes

- Fix signature verification

## Release 1.9.2

### Bugfixes

- Fix statefile location

## Release 1.9.1

### Bugfixes

- Fixed uninstall logic

## Release 1.9.0

### Features

- Provide option to disable puppet from managing the OneAgent service using the
  `manage_service` parameter
- Dynatrace root cert file is now directly passed with module instead of
  requiring archive for download

### Bugfixes

TBD

### Known Issues

TBD

## Release 1.8.0

### Features

- Simplified conditions by setting conditions on class containment on init.pp
- Move uninstall tasks to new `dynatraceoneagent::uninstall` class.

### Bugfixes

- Dynatrace OneAgent Windows uninstalls now executed via PowerShell

### Known Issues

TBD

## Release 1.7.0

### Features

- Add download_options parameter on Archive resource in case custom flags are
  needed for curl/wget/s3 when downloading the OneAgent installer

### Bugfixes

- Added `--restart-service` parameter to `oneagentctl --set-network-zone` command

### Known Issues

TBD

## Release 1.6.0

### Features

- Use shell (`/bin/sh`) to run OneAgent install script on Linux and AIX systems
- Remove resource `file{ $download_path:}` as it is not needed anymore with the
  addition of shell to the install OneAgent command

### Bugfixes

- Fixed if statements with missing or with wrong conditions that checked for the
  AIX/Linux Operating System from the host facts.

### Known Issues

TBD

## Release 1.5.0

### Features

- Add oneagentctl support
- Add option to verify OneAgent Linux/AIX installer file signature
- OneAgent service state can now be set using the `service_state` parameter
- OneAgent package state can now be set using the `package_state` parameter
- Use `reboot` module for both linux and windows reboots
- Convert `host_metadata` string parameter to array
- Convert `host_tags` string parameter to array
- Following best practice, OneAgent metadata including host tags, host metadata
  and hostname is now set via `oneagentclt` instead of configuration files.
- Add `download` class to separately handle OneAgent binary download
- Add windows fact `dynatrace_oneagent_appdata`
- Add windows fact `dynatrace_oneagent_programfiles`
- Add acceptance tests using the Litmus test framework

### Bugfixes

- Remove `ensure => present` from `file{ $download_path:}` resource to ensure no
  file is present if OneAgent installer download fails.
- data/common.yaml file now has valid yaml

### Known Issues

TBD

## Release 1.4.0

### Features

TBD

### Bugfixes

- Make proxy_server param optional

### Known Issues

TBD

## Release 1.3.0

### Features

TBD

### Bugfixes

- Add proxy_server var to init.pp

### Known Issues

TBD

## Release 1.2.0

### Features

- Add proxy server resource for archive module

### Bugfixes

TBD

### Known Issues

TBD

## Release 1.1.0

### Features

TBD

### Bugfixes

- Fix config directory dependency issue by installing OneAgent package in install.pp

### Known Issues

TBD

## Release 1.0.0

### Features

- Ability to set string values to the hostcustomproperties.conf and
  hostautotag.conf of the OneAgent config to add tags and metadata to a host
  entity.
- Ability to override the automatically detected hostname by setting the values
  of the hostname.conf file and restarting the Dynatrace OneAgent service.

### Bugfixes

- Remove debug message for whenever reboot parameter was set to false

### Known Issues

TBD

## Release 0.5.0

### Features

- Ability to download specific version
- Module will automatically detect OS and download required installer
- Module will automatically detect OS and will run the installer package required
- Add AIX support
- Add support for OneAgent Install Params
- Implement Archive module for OneAgent installer downloads
- Reboot functionality included
- Module built and validated with PDK

### Bugfixes

- Fix OneAgent download issue
- Fix module directory issue

### Known Issues

TBD
