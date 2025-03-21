const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const geom_dep = b.dependency("geom", .{
        .target = target,
        .optimize = .ReleaseFast,
    });
    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_mod = b.addModule("sokol_2d", .{
        .root_source_file = b.path("src/Sokol2d.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_mod.addImport("sokol", sokol_dep.module("sokol"));
    lib_mod.addImport("geom", geom_dep.module("geom"));

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "sokol_2d",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    buildShaders(b, target);
}

fn buildShaders(b: *std.Build, target: std.Build.ResolvedTarget) void {
    const sokol_tools_bin_dir = "../sokol-tools-bin/bin/";
    const shaders_dir = "src/shaders/";
    const shaders = .{
        "basic.glsl",
    };
    const optional_shdc: ?[:0]const u8 = comptime switch (builtin.os.tag) {
        .windows => "win32/sokol-shdc.exe",
        .linux => if (builtin.cpu.arch.isX86()) "linux/sokol-shdc" else "linux_arm64/sokol-shdc",
        .macos => if (builtin.cpu.arch.isX86()) "osx/sokol-shdc" else "osx_arm64/sokol-shdc",
        else => null,
    };
    if (optional_shdc == null) {
        std.log.warn("unsupported host platform, skipping shader compiler step", .{});
        return;
    }
    const shdc_path = sokol_tools_bin_dir ++ optional_shdc.?;
    const shdc_step = b.step("shaders", "Compile shaders (needs ../sokol-tools-bin)");
    const glsl = if (isPlatform(target.result, .darwin)) "glsl410" else "glsl430";
    const slang = glsl ++ ":metal_macos:hlsl5:glsl300es:wgsl";
    inline for (shaders) |shader| {
        const cmd = b.addSystemCommand(&.{
            shdc_path,
            "-i",
            shaders_dir ++ shader,
            "-o",
            shaders_dir ++ shader ++ ".zig",
            "-l",
            slang,
            "-f",
            "sokol_zig",
            "--reflection",
        });
        shdc_step.dependOn(&cmd.step);
    }
}

pub const TargetPlatform = enum {
    android,
    linux,
    darwin, // macos and ios
    macos,
    ios,
    windows,
    web,
};

pub fn isPlatform(target: std.Target, platform: TargetPlatform) bool {
    if (builtin.zig_version.major == 0 and builtin.zig_version.minor < 14) {
        // FIXME: remove after zig 0.14.0 release
        return switch (platform) {
            .android => target.abi == .android,
            .linux => target.os.tag == .linux,
            .darwin => target.os.tag.isDarwin(),
            .macos => target.os.tag == .macos,
            .ios => target.os.tag == .ios,
            .windows => target.os.tag == .windows,
            .web => target.cpu.arch.isWasm(),
        };
    } else {
        return switch (platform) {
            .android => target.abi.isAndroid(),
            .linux => target.os.tag == .linux,
            .darwin => target.os.tag.isDarwin(),
            .macos => target.os.tag == .macos,
            .ios => target.os.tag == .ios,
            .windows => target.os.tag == .windows,
            .web => target.cpu.arch.isWasm(),
        };
    }
}
