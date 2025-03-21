const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    const sokol_2d_dep = b.dependency("sokol_2d", .{
        .target = target,
        .optimize = optimize,
    });
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
    });

    sokol_2d_dep.module("sokol_2d").addImport("sokol", sokol_dep.module("sokol"));
    exe_mod.addImport("sokol_2d", sokol_2d_dep.module("sokol_2d"));
    exe_mod.addImport("sokol", sokol_dep.module("sokol"));

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
