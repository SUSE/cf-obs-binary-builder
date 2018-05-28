# cf-obs-binary-builder

This project creates packages in OBS to create binaries for CloudFoundry buildpacks. It is meant to be a drop-in replacement for [binary-builder](https://github.com/cloudfoundry/binary-builder).

## Prerequisites

You need to have a working `osc` environment set up.

## Usage

Define the OBS project using

```
export OBS_PROJECT=the:project
```

Then create a bundler package

```
bin/cf-obs-binary-builder bundler 1.15.1 the_checksum_of_the_sources
```

After the package has been built you can download the binaries incl. the tarball using

```
osc getbinaries the:project bundler-1.15.1 openSUSE_Leap_42.2 x86_64
```

Alternatively you can build a gem:

```
gem build cf_obs_binary_builder.gemspec
```

This command will create a `cf_obs_binary_builder-0.0.0.gem` file which you can install like this:

```
gem install cf_obs_binary_builder-0.0.0.gem
```

After installation you should be able to run the command `cf_obs_binary_builder` directly.
