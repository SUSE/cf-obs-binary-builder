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
./cf-obs-binary-builder
```

After the package has been built you can download the binaries incl. the tarball using

```
osc getbinaries the:project bundler-1.15.1 openSUSE_Leap_42.2 x86_64
```
