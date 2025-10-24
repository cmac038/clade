const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create dependencies
    const datez = b.dependency("datez", .{});
    const zansi = b.dependency("zansi", .{});

    // Create executable for CLI
    const exe = b.addExecutable(.{
        .name = "clade",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            // Add dependencies here
            .imports = &.{
                .{ .name = "datez", .module = datez.module("datez") },
                .{ .name = "zansi", .module = zansi.module("zansi") },
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
    // Expose test step for convenient `zig build test`
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
