//! This program outputs dates which add up to a target number.
//! start_year and end_year delineate the date range.
//! Totals for each year are provided as output.
// TODO: file output options for visualization purposes?
// TODO: better formatting for output; horizontal output?

const std = @import("std");
const stdout = std.io.getStdOut().writer();
const math = std.math;
const testing = std.testing;

const BigDate = struct {
    year: u32,
    month: u32,
    day: u32,

    /// Increment by one day, handling month and year turnovers
    /// Return true if incrementing results in a year turnover
    pub fn increment(this: *BigDate) bool {
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

    /// Returns the date as a u32 encoded as yyyymmdd
    /// For example, 05/26/1987 -> 19870526
    pub inline fn bigDate(self: BigDate) u32 {
        return (self.year * 10000) + (self.month * 100) + self.day;
    }

    /// Print to writer in the format mm/dd/yyyy
    pub inline fn print(self: BigDate, writer: anytype) !void {
        try writer.print("| {:0>2}/{:0>2}/{} |\n", .{ self.month, self.day, self.year });
    }
};

// Pythagorization means adding up all the individual digits
// For example, 05/26/1987 -> 5 + 2 + 6 + 1 + 9 + 8 + 7 = 38
//
// recursive version
fn pythagorizeRecursive(number: u32, divisor: u32) u32 {
    if (divisor == 1) {
        return number;
    }
    return (number / divisor) + pythagorizeRecursive(number % divisor, divisor / 10);
}

// iterative version
fn pythagorizeIterative(input: u32, initial_divisor: u32) u32 {
    var total: u32 = 0;
    var number = input;
    var divisor = initial_divisor;
    total += (number / divisor);
    number %= divisor;
    while (true) {
        if (divisor == 1) {
            total += number;
            break;
        }
        divisor /= 10;
        total += (number / divisor);
        number %= divisor;
    }
    return total;
}

pub fn main() !void {
    // user inputs
    // TODO: turn these into commandline args?
    const target: u32 = 36;
    const start_year: u32 = 0;
    const end_year: u32 = 100000;
    const initial_divisor: u32 = 1e8;

    var buf = std.io.bufferedWriter(stdout);
    var writer = buf.writer();

    try writer.print("Dates with digits that add up to {}:\n", .{target});

    var count: u32 = 0;
    var total: u32 = 0;

    var date = BigDate{
        .year = start_year,
        .month = 1,
        .day = 1,
    };

    try writer.print(
        \\|============|
        \\|    {}    |
        \\|============|
        \\
    , .{date.year});

    while (true) {
        const is_new_year = date.increment();
        if (is_new_year) {
            if (date.year == end_year) {
                // don't print year if it's the last iteration
                try writer.print(
                    \\|------------|
                    \\| Total: {: >3} |
                    \\|============|
                    \\
                , .{count});
                total += count;
                break;
            }
            try writer.print(
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

        if (pythagorizeRecursive(date.bigDate(), initial_divisor) == target) {
            try date.print(writer);
            count += 1;
        }
    }

    try writer.print("\nGrand Total: {}\n", .{total});
    try buf.flush();
}

// TESTING
// pythagorizeRecursive
test "pythagorizeRecursive 1 digit" {
    try testing.expect(pythagorizeRecursive(9, 1) == 9);
}
test "pythagorizeRecursive 2 digit" {
    try testing.expect(pythagorizeRecursive(15, 10) == 6);
}
test "pythagorizeRecursive 3 digit" {
    try testing.expect(pythagorizeRecursive(286, 100) == 16);
}
test "pythagorizeRecursive 4 digit" {
    try testing.expect(pythagorizeRecursive(1996, 1000) == 25);
}
test "pythagorizeRecursive 8 digit" {
    try testing.expect(pythagorizeRecursive(19870526, 1e7) == 38);
}

// pythagorizeIterative
test "pythagorizeIterative 1 digit" {
    const result = pythagorizeIterative(9, 1);
    std.debug.print("pythagorizeIterative 1 digit: {}\n", .{result});
    try testing.expect(result == 9);
}
test "pythagorizeIterative 2 digit" {
    const result = pythagorizeIterative(15, 10);
    std.debug.print("pythagorizeIterative 2 digit: {}\n", .{result});
    try testing.expect(result == 6);
}
test "pythagorizeIterative 3 digit" {
    const result = pythagorizeIterative(286, 100);
    std.debug.print("pythagorizeIterative 3 digit: {}\n", .{result});
    try testing.expect(result == 16);
}
test "pythagorizeIterative 4 digit" {
    const result = pythagorizeIterative(1996, 1000);
    std.debug.print("pythagorizeIterative 4 digit: {}\n", .{result});
    try testing.expect(result == 25);
}
test "pythagorizeIterative 8 digit" {
    const result = pythagorizeIterative(19870526, 1e7);
    std.debug.print("pythagorizeIterative 8 digit: {}\n", .{result});
    try testing.expect(result == 38);
}

// BigDate increment
test "BigDate increment day" {
    var date = BigDate{
        .year = 1950,
        .month = 11,
        .day = 9,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 11 and date.day == 10);
}
test "BigDate increment 30 day month" {
    var date = BigDate{
        .year = 1950,
        .month = 11,
        .day = 30,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 12 and date.day == 1);
}
test "BigDate increment 31 day month" {
    var date = BigDate{
        .year = 1950,
        .month = 8,
        .day = 31,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 9 and date.day == 1);
}
test "BigDate increment February" {
    var date = BigDate{
        .year = 1950,
        .month = 2,
        .day = 28,
    };
    _ = date.increment();
    try testing.expect(date.year == 1950 and date.month == 3 and date.day == 1);
}
test "BigDate increment year" {
    var date = BigDate{
        .year = 1950,
        .month = 12,
        .day = 31,
    };
    _ = date.increment();
    try testing.expect(date.year == 1951 and date.month == 1 and date.day == 1);
}

// BigDate bigDate
test "BigDate bigDate 1" {
    var date = BigDate{
        .year = 1950,
        .month = 11,
        .day = 9,
    };
    try testing.expect(date.bigDate() == 19501109);
}
test "BigDate bigDate 2" {
    var date = BigDate{
        .year = 1950,
        .month = 5,
        .day = 9,
    };
    try testing.expect(date.bigDate() == 19500509);
}
test "BigDate bigDate 3" {
    var date = BigDate{
        .year = 1950,
        .month = 11,
        .day = 11,
    };
    try testing.expect(date.bigDate() == 19501111);
}
test "BigDate bigDate 4" {
    var date = BigDate{
        .year = 1950,
        .month = 5,
        .day = 19,
    };
    try testing.expect(date.bigDate() == 19500519);
}
test "BigDate bigDate 5" {
    var date = BigDate{
        .year = 2000,
        .month = 12,
        .day = 19,
    };
    try testing.expect(date.bigDate() == 20001219);
}
