const std = @import("std");
const sokol = @import("sokol");
const geom = @import("geom");
const Vec2 = geom.Vec2;
const shader = @import("shaders/basic.glsl.zig");

const log = std.log.scoped(.sokol_2d);

const Sokol2d = @This();

const max_commands = 0x1000;

pipeline: sokol.gfx.Pipeline,
vertecies: std.ArrayListUnmanaged(Vertex),
vertex_buffer: sokol.gfx.Buffer,
screen_size: [2]u31,
depth: f32,

const Vertex = extern struct {
    pos: Vec2,
    color0: [4]f32,
};

pub const Color = [4]f32;

pub fn drawRect(s2d: *Sokol2d, x: f32, y: f32, width: f32, height: f32, color: Color) void {
    const h = height;
    const w = width;
    const coords: [6]Vertex = .{
        .{ .pos = .{ .x = x, .y = y + h }, .color0 = color },
        .{ .pos = .{ .x = x, .y = y }, .color0 = color },
        .{ .pos = .{ .x = x + w, .y = y }, .color0 = color },
        .{ .pos = .{ .x = x, .y = y + h }, .color0 = color },
        .{ .pos = .{ .x = x + w, .y = y }, .color0 = color },
        .{ .pos = .{ .x = x + w, .y = y + h }, .color0 = color },
    };
    s2d.vertecies.appendSliceAssumeCapacity(&coords);
}

pub fn drawRectGradient(s2d: *Sokol2d, x: f32, y: f32, width: f32, height: f32, color1: Color, color2: Color, orientation: enum { horisontal, vertical }) void {
    const coords: [6]Vertex = if (orientation == .horisontal) .{
        .{ .pos = .{ .x = x, .y = y + height }, .color0 = color1 },
        .{ .pos = .{ .x = x, .y = y }, .color0 = color1 },
        .{ .pos = .{ .x = x + width, .y = y }, .color0 = color2 },
        .{ .pos = .{ .x = x, .y = y + height }, .color0 = color1 },
        .{ .pos = .{ .x = x + width, .y = y }, .color0 = color2 },
        .{ .pos = .{ .x = x + width, .y = y + height }, .color0 = color2 },
    } else .{
        .{ .pos = .{ .x = x, .y = y + height }, .color0 = color2 },
        .{ .pos = .{ .x = x, .y = y }, .color0 = color1 },
        .{ .pos = .{ .x = x + width, .y = y }, .color0 = color1 },
        .{ .pos = .{ .x = x, .y = y + height }, .color0 = color2 },
        .{ .pos = .{ .x = x + width, .y = y }, .color0 = color1 },
        .{ .pos = .{ .x = x + width, .y = y + height }, .color0 = color2 },
    };
    s2d.vertecies.appendSliceAssumeCapacity(&coords);
}

pub fn drawTriangle(
    s2d: *Sokol2d,
    points: [3]Vec2,
    color: [4]f32,
) void {
    const coords: [6]Vertex = .{
        .{ .pos = points[0], .color0 = color },
        .{ .pos = points[1], .color0 = color },
        .{ .pos = points[2], .color0 = color },
    };
    s2d.vertecies.appendSliceAssumeCapacity(&coords);
}

pub fn drawLine(s2d: *Sokol2d, from: Vec2, to: Vec2, thickness: f32, color: Color) void {
    const dir = from.minus(to).normalized().scaled(thickness / 2);
    const rotated: Vec2 = .{
        .x = -dir.y,
        .y = dir.x,
    };

    const start_up = from.plus(rotated);
    const end_up = to.plus(rotated);
    const start_down = from.minus(rotated);
    const end_down = to.minus(rotated);
    const coords: [6]Vertex = .{
        .{ .pos = start_up, .color0 = color },
        .{ .pos = end_up, .color0 = color },
        .{ .pos = start_down, .color0 = color },
        .{ .pos = start_down, .color0 = color },
        .{ .pos = end_up, .color0 = color },
        .{ .pos = end_down, .color0 = color },
    };
    s2d.vertecies.appendSliceAssumeCapacity(&coords);
}

pub fn drawCircle(s2d: *Sokol2d, center: Vec2, radius: f32, color: Color, num_segments: u32) void {
    const angle_increment = 2 * std.math.pi / @as(f32, @floatFromInt(num_segments));
    var previous_point = Vec2{ .x = center.x + radius, .y = center.y };

    for (0..num_segments) |i| {
        const angle = angle_increment * @as(f32, @floatFromInt(i + 1));
        const next_point = Vec2{
            .x = center.x + radius * std.math.cos(angle),
            .y = center.y + radius * std.math.sin(angle),
        };

        const coords: [3]Vertex = .{
            .{ .pos = center, .color0 = color },
            .{ .pos = previous_point, .color0 = color },
            .{ .pos = next_point, .color0 = color },
        };

        s2d.vertecies.appendSliceAssumeCapacity(&coords);
        previous_point = next_point;
    }
}

pub fn init(gpa: std.mem.Allocator) error{OutOfMemory}!Sokol2d {
    log.info("initing", .{});
    defer log.info("finished init", .{});
    return .{
        .pipeline = sokol.gfx.makePipeline(.{
            .shader = sokol.gfx.makeShader(shader.quadShaderDesc(sokol.gfx.queryBackend())),
            .index_type = .NONE,
            .layout = init: {
                var l = sokol.gfx.VertexLayoutState{};
                l.attrs[shader.ATTR_quad_pos].format = .FLOAT2;
                l.attrs[shader.ATTR_quad_color0].format = .FLOAT4;
                break :init l;
            },
            .cull_mode = .NONE,
        }),
        .vertecies = try .initCapacity(gpa, max_commands),
        .screen_size = .{ 0, 0 },
        .vertex_buffer = sokol.gfx.makeBuffer(.{
            .type = .VERTEXBUFFER,
            .usage = .DYNAMIC,
            .label = "sokol2d vertex buffer",
            .size = max_commands,
        }),
        .depth = 0,
    };
}

pub fn flush(s2d: *Sokol2d) void {
    sokol.gfx.applyViewport(0, 0, s2d.screen_size[0], s2d.screen_size[1], true);
    sokol.gfx.applyPipeline(s2d.pipeline);

    sokol.gfx.updateBuffer(s2d.vertex_buffer, sokol.gfx.asRange(s2d.vertecies.items));
    var bindings: sokol.gfx.Bindings = .{};
    bindings.vertex_buffers[0] = s2d.vertex_buffer;

    sokol.gfx.applyBindings(bindings);
    sokol.gfx.draw(0, @intCast(s2d.vertecies.items.len), 1);
}

pub fn begin(s2d: *Sokol2d, width: u31, height: u31) void {
    s2d.screen_size = .{ width, height };
    s2d.vertecies.clearRetainingCapacity();
    s2d.depth = 0;
}

pub fn deinit(s2d: *Sokol2d) void {
    _ = s2d;
    log.info("deinit", .{});
}
