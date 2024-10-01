## General

- [x] Integrate command line args
- [ ] Implement better output formatting
- [x] Add a build script
- [x] Default behavior with no args: display usage and exit
- [ ] Helper module for reading commandline input and subcommands
- [ ] Target can be a number or a date

## Calculations

- [ ] Sum of digits
- [ ] Life path
- [ ] Tarot
- [ ] Astrology filter for all clade calc

## Commands

- [x] Default: calculate sum of digits for a single date
- [ ] show: output all dates summing to target for a single year
- [ ] range: no print version w/ associated subcommand
- [ ] show-range: current functionality

## Refactoring

- [ ] Try a version with BigDate using arrays
    - e.g. 08/21/1996 -> [_]u8{1, 9, 9, 6, 8, 2, 1}
- [x] Make pythagorize functions BigDate methods? <-- delegator method calls pythagorize algo
- [ ] Factor date parser into a fn
- [ ] Put the print lists back on the stack

## Notes

- numerology library?
    - implement all pythagorean numerology lore
    - implement all chaldean numerology lore
    - calculate tarot cards
    - provide explanations for all results

