const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create module for reusable code
    const mod = b.addModule("clade", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // Create executable for CLI
    const exe = b.addExecutable(.{
        .name = "clade",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "clade", .module = mod },
            },
        }),
    });

    // Add default install step for executable (produces binary via `zig build`)
    b.installArtifact(exe);

    // Make sure artifact installed before running
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    // Allow user to pass args via `zig build run -- args`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    // Expose run step for convenient `zig build run`
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Add unit tests for main.zig
    const exe_unit_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    // Add unit tests for Date.zig
    const date_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/Date.zig"),
            .target = target,
        }),
    });
    const run_date_unit_tests = b.addRunArtifact(date_unit_tests);
    // Expose test step for convenient `zig build test`
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_date_unit_tests.step);
}
