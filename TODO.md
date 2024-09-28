## General

- [x] Integrate command line args
- [ ] Implement better output formatting
- [x] Add a build script
- [ ] Default behavior
- [ ] Subcommands:
    - [ ] Default: calculate pythagorean numerology life path number for a single date
    - [ ] range: no print version w/ associated subcommand
    - [ ] print-range: current functionality

## Refactoring

- [ ] Try a version with BigDate using arrays
    - e.g. 08/21/1996 -> [_]u8{1, 9, 9, 6, 8, 2, 1}
- [x] Make pythagorize functions BigDate methods? <-- delegator method calls pythagorize algo
