# cf-obs-binary-builder

This project creates packages in OBS to create binaries for CloudFoundry buildpacks. It is meant to be a drop-in replacement for [binary-builder](https://github.com/cloudfoundry/binary-builder).

## Prerequisites

You need to have a working `osc` environment set up.

For getting the checksums of the source tarballs of dependencies this tool relies on the `in.cr` of the [depwatcher](https://github.com/cloudfoundry/buildpacks-ci/tree/master/dockerfiles/depwatcher/src/depwatcher) concourse resource. This script has to be compiled and be available as `depwatcher` in the current `PATH`.

To compile the script run

```
$ git clone https://github.com/cloudfoundry/buildpacks-ci
$ cd buildpacks-ci/dockerfiles/depwatcher/
$ crystal src/in.cr -o depwatcher
$ chmod +x depwatcher
$ mv depwatcher /usr/local/bin
```

Example usage of `depwatcher`:

```
$ echo '{"source":{"name":"ruby","type":"ruby"},"version":{"ref":"2.5.1"}}' | depwatcher /tmp > /dev/null
{"source":{"name":"ruby","type":"ruby"},"version":{"ref":"2.5.1"}}
{"ref":"2.5.1","url":"https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz","sha256":"dac81822325b79c3ba9532b048c2123357d3310b2b40024202f360251d9829b1"}
```

The relevant information is returned on STDERR.

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
