# Gobra docker action

This action verifies gobra files in a project

## Inputs

## `caching`

**Required** Wheather or not caching should be enabled (1) or disabled (0)

*Default:*  1

## `projectLocation`

**Required** The relative location of the project in the workflow context, doesn't have to be set normally except in the case, where the GitHub checkout action is used with the `path` option.

*Default:* The action searches for a folder, named like the repo, per default.

## `packageDirectories`

**Required** lookup paths of go packages, relatice to the project directory

*Default:* Same folder as `projectLocation`

## `packages`

**Not Required** Names of the packages that should be verified. Ignores all other packages if 

## `viperBackend`

**Required** Which viper backend to use, one of `SILICON` or `CARBON`

*Default:* `SILICON`

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

## `imageName`

**Required** Which docker image should be used

*Default:* [ghcr.io/viperproject/gobra](https://github.com/viperproject/gobra/pkgs/container/gobra)

## `imageVersion`

**Required** Which image tag should be used

*Default:* latest

## Outputs

## `time`
Total verification time in seconds.

## `numberOfPackages`
Total number of packages that were verified.

## `numberOfFailedPackages`
Total number of packages where the verification returned errors (no timeouts).

## `numberOfTimedoutPackages`
Total number of packages where the verification timed out.

## Example usage

```yaml
uses: jogasser/gobra-action@main
  with:
    javaXss: 64m
    globalTimeout: 1h
    packageTimeout: 10m
    packageLocation: gobra
```