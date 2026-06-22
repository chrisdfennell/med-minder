<!-- Thanks for contributing to MedMinder! -->

## Description

<!-- What does this PR change and why? Link any related issue, e.g. "Closes #12". -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Layout / readability improvement
- [ ] New device support
- [ ] Documentation
- [ ] Other:

## Devices tested

- [ ] `fenix7` (round MIP, buttons)
- [ ] `venu3` / `vivoactive5` (AMOLED, touch)
- [ ] Other:

## Checklist

- [ ] `./build.ps1 -Device <device>` compiles with no errors
- [ ] `./build.ps1 -Export` builds the store package (.iq) for all manifest devices
- [ ] Verified the change in the Connect IQ simulator (`./build.ps1 -Device <device> -Run`)
- [ ] Tested with both buttons and touch where relevant
- [ ] Adding meds via the Garmin Connect app still imports correctly (if settings changed)
- [ ] `DEBUG_SEED` is `false` in `source/DebugSeed.mc`

## Screenshots

<!-- Before/after simulator screenshots for any visual change. -->
