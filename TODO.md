## General

- [x] Integrate command line args
- [ ] Implement better output formatting
- [x] Add a build script
- [ ] Helper module for reading commandline input
- [x] Input a date instead of target number

## Calculations

- [ ] Sum of digits
- [ ] Life path
- [ ] Tarot
- [ ] Astrology filter for all clade calc

## Behavior

- [x] no args: print usage and exit
- [ ] target_date, start_year, end_year: print results
- [ ] -p: print all dates that match + results

## Refactoring

- [ ] Try a version with BigDate using arrays
    - e.g. 08/21/1996 -> [_]u8{1, 9, 9, 6, 8, 2, 1}
- [x] Make pythagorize functions BigDate methods? <-- delegator method calls pythagorize algo
- [x] Factor date parser into a fn
- [x] Put the print lists back on the stack

## Notes

- numerology library?
    - implement all pythagorean numerology lore
    - implement all chaldean numerology lore
    - calculate tarot cards
    - provide explanations for all results

