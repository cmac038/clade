# Clade

CLI program that performs various statistical and numerological calculations for a given date and range of years.  
Written in [Zig](https://ziglang.org/)

### Usage

```
clade [-p] TARGET_DATE START_YEAR END_YEAR
```
- `TARGET_DATE` must be in mm/dd/yyyy form
- `START_YEAR` & `END_YEAR` must be positive integers
- `START_YEAR` < `END_YEAR`
- `START_YEAR` < 1e6
- `END_YEAR` <= 1e6
- `END_YEAR` is **NOT** inclusive
- Include `-p` to print all matching dates

#### Sample Run

```
❯ clade 03/14/1593 0 2025
--------------------------------
            Results:
--------------------------------
  Target date:        03/14/1593
  Target sum:         26
  Life path #:        8
  Year range:         0-2024
  Total occurrences:  42291
  Total days checked: 739617
  Percentage:         5.7180%
  Elapsed time:       28.923ms
--------------------------------
```

#### Sample Print Run

```
❯ clade -p 03/14/1593 2023 2025
|=================|
|      2023       |
|=================|
|   08/29/2023    |
|   09/19/2023    |
|   09/28/2023    |
|-----------------|
|    Total:  3    |
|=================|

|=================|
|      2024       |
|=================|
|   07/29/2024    |
|   08/19/2024    |
|   08/28/2024    |
|   09/09/2024    |
|   09/18/2024    |
|   09/27/2024    |
|-----------------|
|    Total:  6    |
|=================|

--------------------------------
            Results:
--------------------------------
  Target date:        03/14/1593
  Target sum:         26
  Life path #:        8
  Year range:         2023-2024
  Total occurrences:  9
  Total days checked: 731
  Percentage:         1.2312%
  Elapsed time:       0.982ms
--------------------------------
```
