//! This program outputs dates which add up to a target number.
//! start_year and end_year delineate the date range.
//! Totals for each year are provided as output.
// TODO: file output options for visualization purposes?
// TODO: better formatting for output; horizontal output?

const std = @import("std");
const testing = std.testing;
const fmt = std.fmt;
const time = std.time;
const stdout_file = std.io.getStdOut().writer();
const dprint = std.debug.print;

// String statics
const usage =
    \\
    \\    Usage: 
    \\      clade [date (mm/dd/yyyy format)]
    \\      clade [target_sum] [start_year] [end_year]
    \\          - All args must be positive integers
    \\          - start_year < end_year
    \\          - start_year > 1e6
    \\          - end_year >= 1e6
    \\
    \\
;
const error_message = "\n> ERROR: {s} <---\n{s}";

const ArgsError = error{
    TooManyArgs,
    TooFewArgs,
    YearTooBig,
    StartYearGreaterThanEndYear,
    InvalidDateFormat,
};

const Date = struct {
    year: u32,
    month: u32,
    day: u32,

    /// Output takes the format mm/dd/yyyy
    /// Custom format is used for print formatting
    pub fn format(self: Date, comptime format_string: []const u8, options: fmt.FormatOptions, writer: anytype) !void {
        _ = format_string;
        _ = options;

        try writer.print("{:0>2}/{:0>2}/{:<6}", .{ self.month, self.day, self.year });
    }

    /// Increment by one day, handling month and year turnovers
    /// Also handles leap years
    /// Return true if incrementing results in a year turnover
    pub fn increment(this: *Date) bool {
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
    ///     divisible by 4 == true
    ///     divisible by 100 == false EXCEPT when divisible by 400
    pub fn isLeapYear(self: Date) bool {
        if (self.year % 100 == 0) {
            if (self.year % 400 == 0) return true;
            return false;
        }
        return self.year % 4 == 0;
    }

    /// Sum up all the digits in the date
    /// e.g. 06/27/1998 -> 6 + 2 + 7 + 1 + 9 + 9 + 8
    pub fn sumDigits(self: Date) u32 {
        return sumDigitsRecursive(self.year, 100000) + sumDigitsRecursive(self.month, 10) + sumDigitsRecursive(self.day, 10);
    }
};

//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------

pub fn main() !void {
    var timer = try time.Timer.start();

    var buf = std.io.bufferedWriter(stdout_file);
    var stdout = buf.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // handle command-line args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var target: u32 = undefined;
    var start_year: u32 = undefined;
    var end_year: u32 = undefined;

    // no args: print Usage and exit
    if (args.len == 1) {
        try stdout.print("{s}", .{usage});
        try buf.flush();
        return;
    }

    // single arg: calculate sumDigit for one date
    if (args.len == 2) {
        const date_to_sum: Date = try parseDate(allocator, args[1]);
        try stdout.print("Sum of digits in {s}:  {}\n", .{ date_to_sum, date_to_sum.sumDigits() });
        try buf.flush();
        return;
    }

    // multiple args: calculate and print number of dates that add up to target between start_year and target_year
    // do we have the right number of args?
    if (args.len < 4) {
        dprint(error_message, .{ "Too few args!", usage });
        return ArgsError.TooFewArgs;
    }
    if (args.len > 4) {
        dprint(error_message, .{ "Too many args!", usage });
        return ArgsError.TooManyArgs;
    }

    // are the args valid?
    for (args, 1..) |arg, i| {
        switch (i) {
            1 => continue,
            2 => target = fmt.parseUnsigned(u32, arg, 10) catch |err| {
                dprint(error_message, .{ "Invalid arg! target must be a positive integer.", usage });
                return err;
            },
            3 => {
                start_year = fmt.parseUnsigned(u32, arg, 10) catch |err| {
                    dprint(error_message, .{ "Invalid arg! start_year must be a positive integer.", usage });
                    return err;
                };
                if (start_year > 1e6) {
                    dprint(error_message, .{ "start_year is too big!", usage });
                    return ArgsError.YearTooBig;
                }
            },
            4 => {
                end_year = fmt.parseUnsigned(u31, arg, 10) catch |err| {
                    dprint(error_message, .{ "Invalid arg! end_year must be a positive integer.", usage });
                    return err;
                };
                if (end_year > 1e6) {
                    dprint(error_message, .{ "end_year is too big!", usage });
                    return ArgsError.YearTooBig;
                }
            },
            else => unreachable,
        }
    }

    if (start_year > end_year) {
        dprint(error_message, .{ "start_year cannot be greater than end_year!", usage });
        return ArgsError.StartYearGreaterThanEndYear;
    }

    //
    // if we made it here, args are valid!
    //

    // accumulators
    var year_count: u32 = 0;
    var total_occurrences: u32 = 0;
    var total_days: u32 = 0;

    // array to store hits (dates that match the target sum)
    var hits: [36]Date = undefined;

    var date = Date{
        .year = start_year,
        .month = 1,
        .day = 0,
    };

    while (date.year != end_year) {
        const is_new_year = date.increment();
        total_days += 1;
        if (is_new_year) new_year: {
            // skip years with no hits
            if (year_count == 0) break :new_year;
            try stdout.print(
                \\
                \\|=================|
                \\|{:^17}|
                \\|=================|
                \\
            , .{date.year - 1});
            for (0..year_count) |i| {
                try stdout.print("|   {}  |\n", .{hits[i]});
            }
            try stdout.print(
                \\|-----------------|
                \\|    Total:{:>3}    |
                \\|=================|
                \\
            , .{year_count});
            total_occurrences += year_count;
            year_count = 0;
            if (date.year == end_year) break;
        }

        if (date.sumDigits() == target) {
            hits[year_count] = date;
            year_count += 1;
        }
    }

    // an extra day will be counted for the final year; fix that here
    total_days -= 1;

    const elapsed_time: f64 = @as(f64, @floatFromInt(timer.read()));
    try stdout.print(
        \\
        \\--------------------------------
        \\            Results:
        \\--------------------------------
        \\  Target sum:         {}
        \\  Year range:         {}-{}
        \\  Total occurrences:  {}
        \\  Total days checked: {}
        \\  Percentage:         {d:.3}%
        \\  Elapsed time:       {d:.3}ms 
        \\--------------------------------
        \\
    , .{
        target,
        start_year,
        end_year - 1,
        total_occurrences,
        total_days,
        calculatePercentFromInt(total_occurrences, total_days),
        elapsed_time / time.ns_per_ms,
    });
    try buf.flush();
}

//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------

/// Sum digits in a base-10 number; an initial power of 10 divisor must be provided.
/// The divisor is used to deconstruct number e.g.:
///     number = 1956
///     divisor = 1000
///     number / divisor = 1 (int division)
/// This implementation uses recursion to divide the divisor by 10 at each step.
inline fn sumDigitsRecursive(number: u32, divisor: u32) u32 {
    if (divisor == 1) {
        return number;
    }
    return (number / divisor) + sumDigitsRecursive(number % divisor, divisor / 10);
}

/// Sum digits in a base-10 number; an initial power of 10 divisor must be provided.
/// The divisor is used to deconstruct number e.g.:
///     number = 1956
///     divisor = 1000
///     number / divisor = 1 (int division)
/// This implementation uses iteration to divide the divisor by 10 at each step.
fn sumDigitsIterative(input: u32, initial_divisor: u32) u32 {
    var total: u32 = 0;
    var number = input;
    var divisor = initial_divisor;
    while (divisor > 1) : (divisor /= 10) {
        total += (number / divisor);
        number %= divisor;
    }
    return total + number;
}

/// Handle float casts to properly handle percentage calc from ints
fn calculatePercentFromInt(part: u32, whole: u32) f32 {
    return (@as(f32, @floatFromInt(part)) / @as(f32, @floatFromInt(whole))) * 100;
}

/// Takes a date input in the form "mm/dd/yyyy" and returns a Date object
/// "mm/dd/yyyy" format is not strict i.e.
///     mm/dd/yy is valid; yy = 96 will be treated as year 96, not 1996
///     m/d/y is valid
///     mm/d/yyyy is valid
///     mmmmm/dddddd/yyyyyy is valid but ontologically incorrect
///     Any length for any part of the date is valid - it is the order that matters
fn parseDate(allocator: std.mem.Allocator, input: []const u8) !Date {
    var date_breakdown = std.ArrayList(u32).init(allocator);
    defer date_breakdown.deinit();
    var it = std.mem.tokenizeScalar(u8, input, '/');
    while (it.next()) |date_frag| {
        const parsed_date_frag: u32 = fmt.parseUnsigned(u32, date_frag, 10) catch |err| {
            dprint(error_message, .{ "Invalid date format! Use mm/dd/yyyy", usage });
            return err;
        };
        try date_breakdown.append(parsed_date_frag);
    }
    if (date_breakdown.items.len != 3) {
        dprint(error_message, .{ "Invalid date format! Use mm/dd/yyyy", usage });
        return ArgsError.InvalidDateFormat;
    }
    return Date{
        .month = date_breakdown.items[0],
        .day = date_breakdown.items[1],
        .year = date_breakdown.items[2],
    };
}

//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------

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
