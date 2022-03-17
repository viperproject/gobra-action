# Gobra docker action

This action verifies gobra files in a project

## Inputs

## `caching`

**Required** Wheather or not caching should be enabled (1) or disabled (0)

*Default:*  0

## `projectLocation`

**Not Required** Location in which the project is located in the workflow context. Per default the action will look in a folder named the same as the repository(This matches the pull action's default behaviour).

## `srcDirectory`

**Required** Path to the project source directory relative to the `projectLocation`.
*Default:* The projectLocation

## `packageDirectories`

**Not Required** lookup paths of go packages, relative to the `projectLocation`.
*Default:* Same folder as `projectLocation`

## `packages`

**Not Required** Names of the packages that should be verified. If set ignores all packages not contained in this argument.

## `excludePackages`

**Not Required** Names of the packages that should NOT be verified. Takes precedence over the `packages` argument.

## `chop`
**Not Required** In how many pieces a viper program should be chopped for verification. May help verify very large packages

*Default:* 1

## `viperBackend`

**Required** Which viper backend to use, one of `SILICON` or `CARBON`

*Default:* `SILICON`

## `javaXss`

**Required** Java stack size, increase in case of stack overflows

*Default:* 128m

## `javaXmx`

**Required** Java maximum heap size

*Default:* 4g

## `globalTimeout`

**Required** Time till the action as a whole times out. Note that a GitHub workflow step times out automatically after 6 hours.

*Default:* 5h

## `packageTimeout`

**Required** Time till the verification of a package times out.

*Default:* 2h

## `imageName`

**Required** Which docker image should be used.

*Default:* [ghcr.io/viperproject/gobra](https://github.com/viperproject/gobra/pkgs/container/gobra)

## `imageVersion`

**Required** Which image tag should be used.

*Default:* latest

## Outputs

## `time`
Total verification time in seconds.

## Example usage

### Without caching

```yaml
uses: jogasser/gobra-action@main
  with:
    javaXss: 64m
    globalTimeout: 1h
    packageTimeout: 10m
    packageLocation: gobra
```

### With caching

The cache file is located in `${{ runner.workspace }}/.gobra/cache.json`.
This file needs to be stored and resored on subsequent runs to successfully enable caching.
Here is an example with the default GitHub caching action:

```yaml
- name: Cache Viper Server cache
  uses: actions/cache@v2
  env:
    cache-name: vs-cache
  with:
    path: ${{ runner.workspace }}/.gobra/cache.json 
    key: ${{ env.cache-name }}
- name: Verify all Gobra files
  uses: jogasser/gobra-action@main
  with:
    caching: 1
    viperBackend: VSWITHSILICON
```

### Storing artifacts
There are two artifacts generated in this action that are worth to be stored:
 - Once the cache file, located in `${{ runner.workspace }}/.gobra/cache.json`.
 - Once the collected statistics,  located in `${{ runner.workspace }}/.gobra/stats.json`. 

The following workflow excerpt stores these files as artifacts:

```yaml
- name: Verify all Gobra files
  uses: jogasser/gobra-action@main
  with:
    caching: 1
    viperBackend: VSWITHSILICON
- name: Archive cache
  uses: actions/upload-artifact@v2
  with:
    name: cache
    path: ${{ runner.workspace }}/.gobra/cache.json
- name: Archive statistics report
  uses: actions/upload-artifact@v2
  with:
    name: stats
    path: ${{ runner.workspace }}/.gobra/stats.json     

```