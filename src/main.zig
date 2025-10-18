//! This program outputs dates which add up to a target number.
//! START_YEAR and END_YEAR delineate the date range.
//! Matching dates can optionally be printed.

const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;
const fmt = std.fmt;
const time = std.time;
const mem = std.mem;
const log = std.log;
const print = std.debug.print;

// Writers
var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

var stderr_buffer: [1024]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
const stderr = &stderr_writer.interface;

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = myLogFn,
};

fn myLogFn(
    comptime message_level: log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        log.Level.err => ANSI_RED,
        log.Level.warn => ANSI_YELLOW,
        log.Level.debug => ANSI_MAGENTA,
        log.Level.info => ANSI_CYAN,
    } ++ "[" ++ comptime message_level.asText() ++ "]" ++ ANSI_RESET;
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        stderr.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        if (message_level == log.Level.info) stderr.flush() catch return;
    }
}

const Allocator = mem.Allocator;
const ArrayList = std.array_list.Managed;
const Thread = std.Thread;
const Writer = std.Io.Writer;

// ANSI escape sequences
const ANSI_RED = "\x1b[31m";
const ANSI_YELLOW = "\x1b[33m";
const ANSI_BLUE = "\x1b[34m";
const ANSI_CYAN = "\x1b[36m";
const ANSI_MAGENTA = "\x1b[35m";
const ANSI_BLINK = "\x1b[5m";
const ANSI_BOLD = "\x1b[1m";
const ANSI_RESET = "\x1b[0m";

// string statics
const usage = ANSI_BLUE ++
    \\
    \\    Usage: 
    \\      clade [-p] TARGET_DATE START_YEAR END_YEAR
    \\          - TARGET_DATE must be in mm/dd/yyyy form
    \\          - START_YEAR & END_YEAR must be positive integers
    \\          - START_YEAR < END_YEAR
    \\          - START_YEAR < 1e8
    \\          - END_YEAR <= 1e8
    \\          - Include -p to print all matching dates
    \\
    \\
++ ANSI_RESET;

const error_message = ANSI_BLINK ++ ANSI_BOLD ++ ANSI_RED ++ "\n> ERROR: {s} <---" ++ ANSI_RESET ++ "\n{s}";

const ArgsError = error{
    TooManyArgs,
    TooFewArgs,
    YearTooBig,
    StartYearNotLessThanEndYear,
    InvalidDateFormat,
    InvalidFlag,
};

pub const Date = struct {
    const Self = @This();

    year: u32,
    month: u8,
    day: u8,

    /// Output takes the format mm/dd/yyyy
    /// Custom format is used for print formatting
    pub fn format(this: @This(), writer: *Writer) Writer.Error!void {
        try writer.print("{[month]:0>2}/{[day]:0>2}/{[year]}", this);
    }

    /// Increment by one day, handling month and year turnovers
    /// Also handles leap years
    /// Return true if incrementing results in a year turnover
    pub fn increment(this: *Self) void {
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
                if (this.day == 29 and this.isLeapYear()) return;
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
                }
            },
            else => unreachable,
        }
    }

    /// Leap year rules:
    ///     divisible by 4 == true
    ///     divisible by 100 == false EXCEPT when divisible by 400
    pub fn isLeapYear(self: Self) bool {
        return self.year % 4 == 0 and (self.year % 100 != 0 or self.year % 400 == 0);
    }

    /// Sum up all the digits in the date
    /// e.g. 06/27/1998 -> 6 + 2 + 7 + 1 + 9 + 9 + 8
    /// Can sum any date up to year 100,000,000
    pub fn sumDigits(self: Self) u32 {
        return sumDigitsRecursive(self.year, 10000000) + sumDigitsRecursive(self.month, 10) + sumDigitsRecursive(self.day, 10);
    }
};

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

/// Handle float casts to properly calculate percentage from ints
fn calculatePercentFromInt(part: u64, whole: u64) f64 {
    return (@as(f64, @floatFromInt(part)) / @as(f64, @floatFromInt(whole))) * 100;
}

/// Takes a date input in the form "mm/dd/yyyy" and returns a Date object
/// "mm/dd/yyyy" format is not strict i.e.
///     mm/dd/yy is valid; yy = 96 will be treated as year 96, not 1996
///     m/d/y is valid
///     mm/d/yyyy is valid
///     mmmmm/dddddd/yyyyyy is valid but ontologically incorrect
///     Any length for any part of the date is valid - it is the order that matters
fn parseDate(allocator: Allocator, input: []const u8) !Date {
    var date_breakdown = try ArrayList(u32).initCapacity(allocator, 3);
    defer date_breakdown.deinit();
    var it = mem.tokenizeScalar(u8, input, '/');
    while (it.next()) |date_frag| {
        const parsed_date_frag: u32 = fmt.parseUnsigned(u32, date_frag, 10) catch |err| {
            print(error_message, .{ "Invalid date format! Use mm/dd/yyyy", usage });
            return err;
        };
        try date_breakdown.append(parsed_date_frag);
    }
    if (date_breakdown.items.len != 3) {
        print(error_message, .{ "Invalid date format! Use mm/dd/yyyy", usage });
        return ArgsError.InvalidDateFormat;
    }
    return .{
        .month = @as(u8, @intCast(date_breakdown.items[0])),
        .day = @as(u8, @intCast(date_breakdown.items[1])),
        .year = date_breakdown.items[2],
    };
}

/// Validate, parse, and store commandline args for use
/// Arg 1: target date in mm/dd/yyyy format
/// Arg 2: year to start from, positive int < 1e6
/// Arg 3: year to end at, positive int < 1e6
/// Returns the target date for later use
fn parseArgs(allocator: Allocator, args: [][:0]u8, target: *u32, start_year: *u32, end_year: *u32) !Date {
    var target_date: Date = undefined;
    for (args, 0..) |arg, i| {
        switch (i) {
            0 => {
                target_date = try parseDate(allocator, arg);
                target.* = target_date.sumDigits();
            },
            1 => {
                start_year.* = fmt.parseUnsigned(u32, arg, 10) catch |err| {
                    print(error_message, .{ "Invalid arg! START_YEAR must be a positive integer.", usage });
                    return err;
                };
                if (!(start_year.* < 1e8)) {
                    print(error_message, .{ "START_YEAR is too big!", usage });
                    return ArgsError.YearTooBig;
                }
            },
            2 => {
                end_year.* = fmt.parseUnsigned(u31, arg, 10) catch |err| {
                    print(error_message, .{ "Invalid arg! END_YEAR must be a positive integer.", usage });
                    return err;
                };
                if (end_year.* > 1e8) {
                    print(error_message, .{ "END_YEAR is too big!", usage });
                    return ArgsError.YearTooBig;
                }
            },
            else => unreachable,
        }
    }
    if (start_year.* >= end_year.*) {
        print(error_message, .{ "START_YEAR must be less than END_YEAR!", usage });
        return ArgsError.StartYearNotLessThanEndYear;
    }
    return target_date;
}

/// Holds state for multithreading
const ThreadState = struct {
    occurrences: u32,
    days_checked: u32,
};

/// Checks if the sum of date digits for all days between start_year and end_year match the target
/// Counts total days checked and number of matches
fn checkDates(index: usize, start_year: u32, end_year: u32, target: u32, thread_state: *ThreadState) !void {
    var date: Date = .{ .month = 1, .day = 0, .year = start_year };
    while (true) : (thread_state.days_checked += 1) {
        date.increment();
        if (date.year == end_year) break;

        // check for match
        if (date.sumDigits() == target) {
            thread_state.occurrences += 1;
        }
    }
    log.info("Thread {:>2} finished -> {} days checked with {:>9} matches ({d:.4}%)", .{
        index + 1,
        thread_state.days_checked,
        thread_state.occurrences,
        calculatePercentFromInt(thread_state.occurrences, thread_state.days_checked),
    });
}

/// Checks if the sum of date digits for all days between start_year and end_year match the target
/// Counts total days checked and number of matches and stores matches for output (matches param)
fn checkDatesForPrint(allocator: Allocator, index: usize, start_year: u32, end_year: u32, target: u32, thread_state: *ThreadState, matches: *ArrayList(?[]Date)) !void {
    var date: Date = .{ .month = 1, .day = 0, .year = start_year };
    var matchList = ArrayList(Date).init(allocator);
    while (true) : (thread_state.days_checked += 1) {
        date.increment();
        if (date.year == end_year) break;

        // check for match
        if (date.sumDigits() == target) {
            thread_state.occurrences += 1;
            try matchList.append(date);
        }
    }
    log.info("Thread {:>2} finished -> {} days checked with {:>9} matches ({d:.4}%)", .{
        index + 1,
        thread_state.days_checked,
        thread_state.occurrences,
        calculatePercentFromInt(thread_state.occurrences, thread_state.days_checked),
    });
    matches.items[index] = try matchList.toOwnedSlice();
}

//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------

pub fn main() !void {
    var timer = try time.Timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var target_date: Date = undefined;
    var target: u32 = undefined;
    var start_year: u32 = undefined;
    var end_year: u32 = undefined;
    var print_flag: bool = false;

    // handle commandline args
    switch (args.len) {
        1 => {
            try stdout.print("{s}", .{usage});
            try stdout.flush();
            return;
        },
        2, 3 => {
            print(error_message, .{ "Too few args!", usage });
            return ArgsError.TooFewArgs;
        },
        4 => {
            target_date = try parseArgs(allocator, args[1..], &target, &start_year, &end_year);
        },
        5 => {
            if (!mem.eql(u8, args[1], "-p")) {
                print(error_message, .{ "Invalid flag format!", usage });
                return ArgsError.InvalidFlag;
            }
            target_date = try parseArgs(allocator, args[2..], &target, &start_year, &end_year);
            print_flag = true;
        },
        else => {
            print(error_message, .{ "Too many args!", usage });
            return ArgsError.TooManyArgs;
        },
    }

    const cpus = try Thread.getCpuCount();

    var total_occurrences: u64 = 0;
    var total_days: u64 = 0;
    var matches = ArrayList(?[]Date).init(allocator);
    for (0..cpus) |_| {
        try matches.append(null);
    }
    defer matches.deinit();

    // don't multithread when the date range is less than number of logical cores
    if (end_year - start_year < cpus) {
        var thread_state: ThreadState = .{ .occurrences = 0, .days_checked = 0 };
        if (print_flag) {
            try checkDatesForPrint(allocator, 0, start_year, end_year, target, &thread_state, &matches);
        } else {
            try checkDates(0, start_year, end_year, target, &thread_state);
        }
        total_occurrences = thread_state.occurrences;
        total_days = thread_state.days_checked;
    } else { // MULTITHREADING TIMEEEEE
        log.info("Starting {} threads...", .{cpus});
        // storage for Thread accumulators
        var thread_accumulators = try ArrayList(ThreadState).initCapacity(allocator, cpus);
        defer thread_accumulators.deinit();
        try thread_accumulators.appendNTimes(.{ .occurrences = 0, .days_checked = 0 }, cpus);
        // keep track of thread handles
        var handles = try ArrayList(Thread).initCapacity(allocator, cpus);
        defer handles.deinit();
        // calculate chunk size (number of years each thread will check)
        const chunk = (end_year - start_year) / @as(u32, @intCast(cpus));
        var start: u32 = start_year;
        // start threads with different fn depending on if output will be printed
        for (0..cpus - 1) |i| {
            const end = start + chunk;
            var handle: Thread = undefined;
            if (print_flag) {
                handle = try Thread.spawn(.{}, checkDatesForPrint, .{ allocator, i, start, end, target, &thread_accumulators.items[i], &matches });
            } else {
                handle = try Thread.spawn(.{}, checkDates, .{ i, start, end, target, &thread_accumulators.items[i] });
            }
            try handles.append(handle);
            start += chunk;
        }
        // last thread handles remaining years (sometimes bigger than chunk)
        var lastHandle: Thread = undefined;
        if (print_flag) {
            lastHandle = try Thread.spawn(.{}, checkDatesForPrint, .{ allocator, cpus - 1, start, end_year, target, &thread_accumulators.items[cpus - 1], &matches });
        } else {
            lastHandle = try Thread.spawn(.{}, checkDates, .{ cpus - 1, start, end_year, target, &thread_accumulators.items[cpus - 1] });
        }
        try handles.append(lastHandle);

        // resolve threads before moving forward
        for (handles.items) |handle| {
            handle.join();
        }

        for (thread_accumulators.items) |thread_state| {
            total_days += thread_state.days_checked;
            total_occurrences += thread_state.occurrences;
        }
    }

    if (print_flag) {
        try stdout.print(
            \\
            \\    Matches:
            \\----------------
            \\
        , .{});
    }
    const date_struct_size = @sizeOf(Date);
    var total_size: u64 = 0;
    for (matches.items, 1..) |match_slice, i| {
        if (match_slice) |match| {
            log.debug("slice {:>2}: {:>9} | size: {d:.4} MB", .{ i, match.len, @as(f32, @floatFromInt(match.len * date_struct_size)) / 1e6 });
            total_size += match.len * date_struct_size;
            if (print_flag and match.len > 0) {
                for (match) |date| try stdout.print(">  {f}\n", .{date});
            }
            allocator.free(match);
        }
    }
    log.debug("total heap usage: {d:.5} GB", .{@as(f32, @floatFromInt(total_size)) / 1e9});
    if (total_size > 4e9) log.warn("heap size over 5 GB!!!", .{});

    const elapsed_time: f64 = @as(f64, @floatFromInt(timer.read()));
    try stdout.print(
        \\
        \\--------------------------------
        \\            Results:
        \\--------------------------------
        \\  Target date:        {f}
        \\  Target sum:         {d}
        \\  Life path #:        {d}
        \\  Year range:         {d}-{d}
        \\  Total occurrences:  {d}
        \\  Total days checked: {d}
        \\  Percentage:         {d:.4}%
        \\  Elapsed time:       {d:.3}ms 
        \\--------------------------------
        \\
    , .{
        target_date,
        target,
        sumDigitsIterative(target, 10),
        start_year,
        end_year - 1,
        total_occurrences,
        total_days,
        calculatePercentFromInt(total_occurrences, total_days),
        elapsed_time / time.ns_per_ms,
    });
    try stdout.flush();
    stderr.flush() catch return;
}

//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------

// TESTING
// sumDigitsRecursive
test "sumDigitsRecursive 1 digit" {
    try testing.expectEqual(9, sumDigitsRecursive(9, 1));
}
test "sumDigitsRecursive 2 digit" {
    try testing.expectEqual(6, sumDigitsRecursive(15, 10));
}
test "sumDigitsRecursive 3 digit" {
    try testing.expectEqual(16, sumDigitsRecursive(286, 100));
}
test "sumDigitsRecursive 4 digit" {
    try testing.expectEqual(25, sumDigitsRecursive(1996, 1000));
}
test "sumDigitsRecursive 8 digit" {
    try testing.expectEqual(38, sumDigitsRecursive(19870526, 1e7));
}

// sumDigitsIterative
test "sumDigitsIterative 1 digit" {
    try testing.expectEqual(9, sumDigitsIterative(9, 1));
}
test "sumDigitsIterative 2 digit" {
    try testing.expectEqual(6, sumDigitsIterative(15, 10));
}
test "sumDigitsIterative 3 digit" {
    try testing.expectEqual(16, sumDigitsIterative(286, 100));
}
test "sumDigitsIterative 4 digit" {
    try testing.expectEqual(25, sumDigitsIterative(1996, 1000));
}
test "sumDigitsIterative 8 digit" {
    try testing.expectEqual(38, sumDigitsIterative(19870526, 1e7));
}

// parseDate
test "parseDate 1" {
    const allocator = testing.allocator;
    const date = Date{ .year = 2023, .month = 10, .day = 7 };
    const parsed_date = try parseDate(allocator, "10/7/2023");
    try testing.expectEqualDeep(date, parsed_date);
}
test "parseDate 2" {
    const allocator = testing.allocator;
    const date = Date{ .year = 2023, .month = 10, .day = 7 };
    const parsed_date = try parseDate(allocator, "10/07/2023");
    try testing.expectEqualDeep(date, parsed_date);
}
test "parseDate 3" {
    const allocator = testing.allocator;
    const date = Date{ .year = 2023, .month = 1, .day = 7 };
    const parsed_date = try parseDate(allocator, "1/7/2023");
    try testing.expectEqualDeep(date, parsed_date);
}
test "parseDate 4" {
    const allocator = testing.allocator;
    const date = Date{ .year = 2023, .month = 1, .day = 7 };
    const parsed_date = try parseDate(allocator, "1/07/2023");
    try testing.expectEqualDeep(date, parsed_date);
}
test "parseDate 5" {
    const allocator = testing.allocator;
    const date = Date{ .year = 2023, .month = 1, .day = 7 };
    const parsed_date = try parseDate(allocator, "01/07/2023");
    try testing.expectEqualDeep(date, parsed_date);
}
test "parseDate 6" {
    const allocator = testing.allocator;
    try testing.expectError(ArgsError.InvalidDateFormat, parseDate(allocator, "01/17"));
}

// Date isLeapYear
test "Date isLeapYear divisible by 4 (true)" {
    const date = Date{ .year = 2024, .month = 8, .day = 5 };
    try testing.expect(date.isLeapYear());
}
test "Date isLeapYear divisible by 400 (true)" {
    const date = Date{ .year = 2000, .month = 8, .day = 5 };
    try testing.expect(date.isLeapYear());
}
test "Date isLeapYear divisible by 100 (false)" {
    const date = Date{ .year = 2100, .month = 8, .day = 5 };
    try testing.expect(!date.isLeapYear());
}
test "Date isLeapYear (false)" {
    const date = Date{ .year = 2022, .month = 8, .day = 5 };
    try testing.expect(!date.isLeapYear());
}
test "Date isLeapYear (true)" {
    const date = Date{ .year = 1996, .month = 8, .day = 5 };
    try testing.expect(date.isLeapYear());
}

// Date increment
test "Date increment day" {
    var date = Date{
        .year = 1950,
        .month = 11,
        .day = 9,
    };
    date.increment();
    try testing.expect(date.year == 1950 and date.month == 11 and date.day == 10);
}
test "Date increment 30 day month" {
    var date = Date{
        .year = 1950,
        .month = 11,
        .day = 30,
    };
    date.increment();
    try testing.expect(date.year == 1950 and date.month == 12 and date.day == 1);
}
test "Date increment 31 day month" {
    var date = Date{
        .year = 1950,
        .month = 8,
        .day = 31,
    };
    date.increment();
    try testing.expect(date.year == 1950 and date.month == 9 and date.day == 1);
}
test "Date increment February (not Leap Year)" {
    var date = Date{
        .year = 1950,
        .month = 2,
        .day = 28,
    };
    date.increment();
    try testing.expect(date.year == 1950 and date.month == 3 and date.day == 1);
}
test "Date increment February (Leap Year)" {
    var date = Date{
        .year = 2024,
        .month = 2,
        .day = 28,
    };
    date.increment();
    try testing.expect(date.year == 2024 and date.month == 2 and date.day == 29);
}
test "Date increment year" {
    var date = Date{
        .year = 1950,
        .month = 12,
        .day = 31,
    };
    date.increment();
    try testing.expect(date.year == 1951 and date.month == 1 and date.day == 1);
}

// Date sumDigits
test "Date sumDigits 12/31/1950" {
    const date = Date{
        .year = 1950,
        .month = 12,
        .day = 31,
    };
    try testing.expectEqual(22, date.sumDigits());
}
test "Date sumDigits 08/21/1996" {
    const date = Date{
        .year = 1996,
        .month = 8,
        .day = 21,
    };
    try testing.expectEqual(36, date.sumDigits());
}
