# Clade

CLI program that performs various statistical and numerological calculations for a given date and range of years.  
Written in [Zig](https://ziglang.org/).

### Usage

```
clade [-p] TARGET_DATE START_YEAR END_YEAR
```
- `TARGET_DATE` must be in mm/dd/yyyy form
- `START_YEAR` & `END_YEAR` must be positive integers
- `START_YEAR` < `END_YEAR`
- `END_YEAR` is **NOT** inclusive
- Include `-p` to print all matching dates
- The application multithreads by default with the max available CPU cores

#### Sample Run

```
❯ clade 03/14/1593 0 2025
[info]: Starting 16 threads...
[info]: Thread 13 finished -> 46022 days checked with      3155 matches (6.8554%)
[info]: Thread  4 finished -> 46020 days checked with      2778 matches (6.0365%)
[info]: Thread  6 finished -> 46020 days checked with      3268 matches (7.1013%)
[info]: Thread 14 finished -> 46020 days checked with      3364 matches (7.3099%)
[info]: Thread  2 finished -> 46020 days checked with      1830 matches (3.9765%)
[info]: Thread  7 finished -> 46022 days checked with      3296 matches (7.1618%)
[info]: Thread 10 finished -> 46021 days checked with      2315 matches (5.0303%)
[info]: Thread 12 finished -> 46019 days checked with      2887 matches (6.2735%)
[info]: Thread 11 finished -> 46021 days checked with      2829 matches (6.1472%)
[info]: Thread 15 finished -> 46021 days checked with      3028 matches (6.5796%)
[info]: Thread  3 finished -> 46021 days checked with      2494 matches (5.4193%)
[info]: Thread  9 finished -> 46021 days checked with      1632 matches (3.5462%)
[info]: Thread 16 finished -> 49308 days checked with      2527 matches (5.1249%)
[info]: Thread  1 finished -> 46021 days checked with      1272 matches (2.7640%)
[info]: Thread  5 finished -> 46021 days checked with      2889 matches (6.2776%)
[info]: Thread  8 finished -> 46019 days checked with      2727 matches (5.9258%)

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
  Elapsed time:       8.444ms
--------------------------------
```

#### Sample Print Run

```
❯ clade -p 03/14/1593 2023 2025
[info]: Thread  1 finished -> 731 days checked with         9 matches (1.2312%)

    Matches:
----------------
>  08/29/2023
>  09/19/2023
>  09/28/2023
>  07/29/2024
>  08/19/2024
>  08/28/2024
>  09/09/2024
>  09/18/2024
>  09/27/2024

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
  Elapsed time:       0.247ms
--------------------------------
```
