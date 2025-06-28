const std = @import("std");
const builtin = @import("builtin");
const sokol = @import("sokol");
const Build = std.Build;

pub fn build(b: *Build) !void {
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

    const shd = try createShaderModule(b, sokol_dep);
    lib.root_module.addImport("shader", shd);
}

// compile shader via sokol-shdc
fn createShaderModule(b: *Build, dep_sokol: *Build.Dependency) !*Build.Module {
    const mod_sokol = dep_sokol.module("sokol");
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    return sokol.shdc.createModule(b, "shader", mod_sokol, .{
        .shdc_dep = dep_shdc,
        .input = "src/shaders/basic.glsl",
        .output = "shader.zig",
        .slang = .{
            .glsl410 = true,
            .glsl300es = true,
            .hlsl4 = true,
            .metal_macos = true,
            .wgsl = true,
        },
    });
}
