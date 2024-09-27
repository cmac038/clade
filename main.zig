// This program outputs dates which add up to a target number.
// start_year and end_year delineate the date range.
// Totals for each year are provided as output.
// TODO: file output options for visualization purposes?
// TODO: better formatting for output; horizontal, buffered output?

const std = @import("std");
const stdout = std.io.getStdOut().writer();
const testing = std.testing;

pub fn main() !void {
    // user inputs
    // TODO: turn these into commandline args?
    const target: u32 = 36;
    const start_year: u32 = 0;
    const end_year: u32 = 100000;
    const num_digits: u32 = 10;

    try stdout.print("Dates with digits that add up to {}:\n", .{target});

    var count: u32 = 0;
    var total: u32 = 0;
    var year = start_year;
    var month: u32 = 1;
    var day: u32 = 1;
    var date = convertToBigDate(year, month, day);
    try stdout.print(
        \\|============|
        \\|    {}    |
        \\|============|
        \\
    , .{year});

    while (year < end_year) : (date = convertToBigDate(year, month, day)) {
        // handle different month lengths
        switch (month) {
            1, 3, 5, 7, 8, 10, 12 => {
                if (day > 31) {
                    month += 1;
                    day = 1;
                }
            },
            4, 6, 9, 11 => {
                if (day > 30) {
                    month += 1;
                    day = 1;
                }
            },
            2 => {
                if (day > 28) {
                    month += 1;
                    day = 1;
                }
            },
            else => unreachable,
        }

        // handle year turnover
        if (month > 12) {
            year += 1;
            month = 1;
            day = 1;
            if (year == end_year) {
                // don't print year if it's the last iteration
                try stdout.print(
                    \\|------------|
                    \\| Total: {: >3} |
                    \\|============|
                    \\
                , .{count});
                continue;
            }
            try stdout.print(
                \\|------------|
                \\| Total: {: >3} |
                \\|============|
                \\|    {}    |
                \\|============|
                \\
            , .{ count, year });
            total += count;
            count = 0;
            continue;
        }

        // date will always be a valid date at this point
        if (pythagorizeIterative(date, num_digits) == target) {
            try stdout.print("| {:0>2}/{:0>2}/{} |\n", .{ month, day, year });
            count += 1;
        }

        day += 1;
    }

    try stdout.print("\nGrand Total: {}\n", .{total});
}

// Pythagorization means adding up all the individual digits.
// For example, 05/26/1987 -> 5 + 2 + 6 + 1 + 9 + 8 + 7 = 38
//
// recursive version
fn pythagorizeRecursive(number: u32, num_digits: u32) u32 {
    if (num_digits == 1) {
        return number;
    }
    const divisor = std.math.pow(u32, 10, num_digits - 1);
    return (number / divisor) + pythagorizeRecursive(number % divisor, num_digits - 1);
}

// iterative version
fn pythagorizeIterative(input: u32, num_digits: u32) u32 {
    var total: u32 = 0;
    var number = input;
    var i = num_digits;
    while (i > 0) : (i -= 1) {
        if (i == 1) {
            total += number;
            continue;
        }
        const divisor = std.math.pow(u32, 10, i - 1);
        total += (number / divisor);
        number %= divisor;
    }
    return total;
}

// BigDate = date in the format yyyymmdd.
// For example, 05/26/1987 -> 19870526
inline fn convertToBigDate(year: u32, month: u32, day: u32) u32 {
    return (year * 10000) + (month * 100) + day;
}

// TESTING
test "pythagorizeRecursive 1 digit" {
    try testing.expect(pythagorizeRecursive(9, 1) == 9);
}

test "pythagorizeRecursive 2 digit" {
    try testing.expect(pythagorizeRecursive(15, 2) == 6);
}

test "pythagorizeRecursive 3 digit" {
    try testing.expect(pythagorizeRecursive(286, 3) == 16);
}

test "pythagorizeRecursive 4 digit" {
    try testing.expect(pythagorizeRecursive(1996, 4) == 25);
}

test "pythagorizeIterative 1 digit" {
    try testing.expect(pythagorizeIterative(9, 1) == 9);
}

test "pythagorizeIterative 2 digit" {
    try testing.expect(pythagorizeIterative(15, 2) == 6);
}

test "pythagorizeIterative 3 digit" {
    try testing.expect(pythagorizeIterative(286, 3) == 16);
}

test "pythagorizeIterative 4 digit" {
    try testing.expect(pythagorizeIterative(1996, 4) == 25);
}

test "pythagorizeIterative 8 digit" {
    try testing.expect(pythagorizeIterative(19870526, 8) == 38);
}
