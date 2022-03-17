# Gobra docker action

This action verifies gobra files in a project

## Inputs

## `caching`

**Required** Wheather or not caching should be enabled (1) or disabled (0)

*Default:*  0

## `srcDirectory`

**Required** Path to the project source directory, needs to include the path, to where the project was pulled to.
*Default:* The project root

## `packageDirectories`

**Not Required** lookup paths of go packages, relatice to the project directory

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