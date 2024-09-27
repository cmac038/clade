//! This program outputs dates which add up to a target number.
//! start_year and end_year delineate the date range.
//! Totals for each year are provided as output.
// TODO: file output options for visualization purposes?
// TODO: better formatting for output; horizontal output?

const std = @import("std");
const stdout_file = std.io.getStdOut().writer();
const testing = std.testing;

const Date = struct {
    year: u32,
    month: u32,
    day: u32,

    /// Increment by one day, handling month and year turnovers
    /// Also handles leap years
    /// Return true if incrementing results in a year turnover
    pub inline fn increment(this: *Date) bool {
        this.day += 1;
        // check for turnover
        switch (this.month) {
            // 31 day months
            1, 3, 5, 7, 8, 10 => {
                if (this.day > 31) {
                    this.month += 1;
                    this.day = 1;
                }
            },
            // 30 day months
            4, 6, 9, 11 => {
                if (this.day > 30) {
                    this.month += 1;
                    this.day = 1;
                }
            },
            // February
            2 => {
                if (this.day == 29 and this.isLeapYear()) return false;
                if (this.day > 28) {
                    this.month += 1;
                    this.day = 1;
                }
            },
            // December (year turnover)
            12 => {
                if (this.day > 31) {
                    this.year += 1;
                    this.month = 1;
                    this.day = 1;
                    return true;
                }
            },
            else => unreachable,
        }
        return false;
    }

    /// Leap year rules:
    /// divisible by 4 == true
    /// divisible by 100 == false EXCEPT when divisible by 400
    pub inline fn isLeapYear(self: Date) bool {
        if (self.year % 100 == 0) {
            if (self.year % 400 == 0) return true;
            return false;
        }
        return self.year % 4 == 0;
    }

    /// Sum up all the digits in the date
    /// e.g. 06/27/1998 -> 6 + 2 + 7 + 1 + 9 + 9 + 8
    pub inline fn sumDigits(self: Date) u32 {
        return sumDigitsRecursive(self.year, 10000) + sumDigitsRecursive(self.month, 10) + sumDigitsRecursive(self.day, 10);
    }

    /// Print to writer in the format mm/dd/yyyy
    pub inline fn print(self: Date, writer: anytype) !void {
        try writer.print("| {:0>2}/{:0>2}/{} |\n", .{ self.month, self.day, self.year });
    }
};

inline fn sumDigitsRecursive(number: u32, divisor: u32) u32 {
    if (divisor == 1) {
        return number;
    }
    return (number / divisor) + sumDigitsRecursive(number % divisor, divisor / 10);
}

inline fn sumDigitsIterative(input: u32, initial_divisor: u32) u32 {
    var total: u32 = 0;
    var number = input;
    var divisor = initial_divisor;
    while (divisor > 1) : (divisor /= 10) {
        total += (number / divisor);
        number %= divisor;
    }
    return total + number;
}

pub fn main() !void {
    // user inputs
    // TODO: turn these into commandline args?
    const target: u32 = 36;
    const start_year: u32 = 0;
    const end_year: u32 = 100000;

    // buffered writer for better performance
    var buf = std.io.bufferedWriter(stdout_file);
    var stdout = buf.writer();

    // accumulators
    var count: u32 = 0;
    var total: u32 = 0;

    var date = Date{
        .year = start_year,
        .month = 1,
        .day = 1,
    };

    try stdout.print(
        \\Dates with digits that add up to {}:
        \\
        \\|============|
        \\|    {}    |
        \\|============|
        \\
    , .{ target, date.year });

    while (true) {
        const is_new_year = date.increment();
        if (is_new_year) {
            if (date.year == end_year) {
                // don't print year if it's the last iteration
                try stdout.print(
                    \\|------------|
                    \\| Total: {: >3} |
                    \\|============|
                    \\
                , .{count});
                total += count;
                break;
            }
            try stdout.print(
                \\|------------|
                \\| Total: {: >3} |
                \\|============|
                \\|    {}    |
                \\|============|
                \\
            , .{ count, date.year });
            total += count;
            count = 0;
        }

        if (date.sumDigits() == target) {
            try date.print(stdout);
            count += 1;
        }
    }

    try stdout.print("\nGrand Total: {}\n", .{total});
    try buf.flush();
}

// TESTING
// sumDigitsRecursive
test "sumDigitsRecursive 1 digit" {
    try testing.expect(sumDigitsRecursive(9, 1) == 9);
}
test "sumDigitsRecursive 2 digit" {
    try testing.expect(sumDigitsRecursive(15, 10) == 6);
}
test "sumDigitsRecursive 3 digit" {
    try testing.expect(sumDigitsRecursive(286, 100) == 16);
}
test "sumDigitsRecursive 4 digit" {
    try testing.expect(sumDigitsRecursive(1996, 1000) == 25);
}
test "sumDigitsRecursive 8 digit" {
    try testing.expect(sumDigitsRecursive(19870526, 1e7) == 38);
}

// sumDigitsIterative
test "sumDigitsIterative 1 digit" {
    try testing.expect(sumDigitsIterative(9, 1) == 9);
}
test "sumDigitsIterative 2 digit" {
    try testing.expect(sumDigitsIterative(15, 10) == 6);
}
test "sumDigitsIterative 3 digit" {
    try testing.expect(sumDigitsIterative(286, 100) == 16);
}
test "sumDigitsIterative 4 digit" {
    try testing.expect(sumDigitsIterative(1996, 1000) == 25);
}
test "sumDigitsIterative 8 digit" {
    try testing.expect(sumDigitsIterative(19870526, 1e7) == 38);
}

// Date isLeapYear
test "Date isLeapYear divisible by 4 (true)" {
    var date = Date{ .year = 2024, .month = 8, .day = 5 };
    try testing.expect(date.isLeapYear());
}
test "Date isLeapYear divisible by 400 (true)" {
    var date = Date{ .year = 2000, .month = 8, .day = 5 };
    try testing.expect(date.isLeapYear());
}
test "Date isLeapYear divisible by 100 (false)" {
    var date = Date{ .year = 2100, .month = 8, .day = 5 };
    try testing.expect(!date.isLeapYear());
}
test "Date isLeapYear (false)" {
    var date = Date{ .year = 2022, .month = 8, .day = 5 };
    try testing.expect(!date.isLeapYear());
}

// Date increment
test "Date increment day" {
    var date = Date{
        .year = 1950,
        .month = 11,
        .day = 9,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 11 and date.day == 10);
}
test "Date increment 30 day month" {
    var date = Date{
        .year = 1950,
        .month = 11,
        .day = 30,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 12 and date.day == 1);
}
test "Date increment 31 day month" {
    var date = Date{
        .year = 1950,
        .month = 8,
        .day = 31,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 9 and date.day == 1);
}
test "Date increment February (not Leap Year)" {
    var date = Date{
        .year = 1950,
        .month = 2,
        .day = 28,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 3 and date.day == 1);
}
test "Date increment February (Leap Year)" {
    var date = Date{
        .year = 2024,
        .month = 2,
        .day = 28,
    };
    _ = date.increment();
    try testing.expect(date.year == 2024 and date.month == 2 and date.day == 29);
}
test "Date increment year" {
    var date = Date{
        .year = 1950,
        .month = 12,
        .day = 31,
    };
    _ = date.increment();
    try testing.expect(date.year == 1951 and date.month == 1 and date.day == 1);
}

// Date sumDigits
test "Date sumDigits 12/31/1950" {
    var date = Date{
        .year = 1950,
        .month = 12,
        .day = 31,
    };
    try testing.expect(date.sumDigits() == 22);
}
test "Date sumDigits 08/21/1996" {
    var date = Date{
        .year = 1996,
        .month = 8,
        .day = 21,
    };
    try testing.expect(date.sumDigits() == 36);
}
