# Gobra docker action

This action verifies gobra files in a project

## Inputs

## `caching`

**Required** Wheather or not caching should be enabled (1) or disabled (0)

*Default:*  1

## `projectLocation`

**Required** The relative location of the project in the workflow context, doesn't have to be set normally except in the case, where the GitHub checkout action is used with the `path` option.

*Default:* The action searches for a folder, named like the repo, per default.

## `packageLocation`

**Required** Where the gobra packages are located under the `projectLocation` folder.

*Default:* Same folder as `projectLocation`

## `packages`

**Not Required** Which packages should be verified, should be a list of directories relative to `packageLocation`.

## `javaXss`

**Required** Java stack size, increase in case of stack overflows

*Default:* 128m

## `javaXmx`

**Required** Java maximum heap size

*Default:* 256m


## `globalTimeout`

**Required** Time till the action as a whole times out

*Default:* 3h

## `packageTimeout`

**Required** Time till the verification of a package times out

*Default:* 1h

## `imageVersion`

**Required** Which [gobra docker image](https://github.com/jogasser/gobra/pkgs/container/gobra) tag should be used (

*Default:* latest

## Outputs

## `time`
Total verification time in seconds.

## `numberOfPackages`
Total number of packages that were verified.

## `numberOfFailedPackages`
Total number of packages where the verification returned errors (no timeouts).

## `numberOfTimetoutPackages`
Total number of packages where the verification timed out.

## Example usage

uses: jogasser/gobra-action@main
  with:
    javaXss: 64m
    globalTimeout: 1h
    packageTimeout: 10m
    packageLocation: gobra
          
