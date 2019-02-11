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

### Set environment variables
Define the OBS project using

```
export OBS_PROJECT=the:project
```

Define the stack mappings (needed for `buildpack`, `sync` and `regenerate_specs` command) e.g.

```
export STACK_MAPPINGS='{ "sle12":"cflinuxfs2", "opensuse42": "cflinuxfs2", "sle15": "cflinuxfs3" }'
```

This instructs the `cf_obs_binary_builder` to use certain stacks in the manifest when picking depencencies for the stacks to add.
In the example above, the cflinuxfs2 stack will be used to pick dependencies for the sle12 stack. In the same way, the cflinuxfs3 will be used
to select dependencies for sle15 and so on.

### `cf_obs_binary_builder dependency`

This command will create a new package on obs. This command is interally used by the sync command (see below). Run manually for testing purposes only.
You can find the required checksum by running the depwatcher as described above.

```
cf_obs_binary_builder dependency <dependency> <version> <checksum>
```

**Example:**

```
cf_obs_binary_builder dependency node 6.16.0 5432c6cba59bfef5794951193e93dbbd1707960b6c722925afcdb4517f4dc742
```


### `cf_obs_binary_builder buildpack`

This creates a new buildpack on obs. you need to set the `STACK_MAPPINGS` variable as described above. Revision is a number used to create a version string for our releases (usually it is the upstream version appended with SUSE revision number e.g. `1.17.0` => `1.17.0.1`). This number is incremented with every release on a certain upstream version.
The upstream version tags have to be synced into our fork of buildpack (e.g. https://github.com/SUSE/cf-dotnet-core-buildpack/tags) for this to work.

```
  cf_obs_binary_builder buildpack <buildpack> <upstream-version> <revision>
```

**Example:**

```
  cf_obs_binary_builder buildpack dotnet-core 2.2.5 1
```

### `cf_obs_binary_builder sync`

This command creates missing OBS packages for all the stacks in `STACK_MAPPINGS` keys using the given manifest. Again the `STACK_MAPPINGS` needs to be set for this to work. For existing dependencies it will internally run the `regenerate` command as mentioned on the paragraph below. In the end if there are unknown dependencies it will exit with an error.
The manifest argument needs to point to a file on the local filesystem.

```
cf_obs_binary_builder sync <manifest_path>
```

**Example:**

If `STACK_MAPPINGS` is this:

```
export STACK_MAPPINGS='{ "sle12":"cflinuxfs2", "opensuse42": "cflinuxfs2", "sle15": "cflinuxfs3" }'
```

the command will create packages for all the cflinuxfs2 and cflinuxfs3 depedencies in the given manifest file (because these are the reference stacks for the stacks we want to add).

### `cf_obs_binary_builder regenerate-specs`

Regenerates the spec files for all (existing) dependencies on OBS. The `STACK_MAPPINGS` needs to be set for this to work (Mappings work as described in the `sync` section above). The manifest argument needs to point to a file on the local filesystem. This will not genereate packages for missing dependencies, it will only regenerate spec-files for existing dependencies.

```
cf_obs_binary_builder regenerate-specs <manifest_path>
```

### Building

If you don't want to use the `cf_obs_binary_builder` as a script in `$(pwd)/bin` you can build it as a rubygem

```
gem build cf_obs_binary_builder.gemspec
```

This command will create a `cf_obs_binary_builder-0.0.0.gem` file which you can install like this:

```
gem install cf_obs_binary_builder-0.0.0.gem
```

After installation you should be able to run the command `cf_obs_binary_builder` directly.
