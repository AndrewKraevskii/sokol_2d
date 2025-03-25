const std = @import("std");
const sokol = @import("sokol");
const geom = @import("geom");
const Vec2 = geom.Vec2;
const Mat2x3 = geom.Mat2x3;
const shader = @import("shaders/basic.zig");

const log = std.log.scoped(.sokol_2d);

const Sokol2d = @This();

const max_vertecies = 0x10000;

pipeline: sokol.gfx.Pipeline,
vertecies: std.ArrayListUnmanaged(Vertex),
vertex_buffer: sokol.gfx.Buffer,
viewport: AABB,
projection: Mat2x3,

pub const AABB = extern struct {
    start: Vec2,
    end: Vec2,

    pub fn fromCenterSize(center: Vec2, size_: Vec2) AABB {
        return .{
            .start = center.plusScaled(size_, -0.5),
            .end = center.plusScaled(size_, 0.5),
        };
    }

    pub fn size(aabb: AABB) Vec2 {
        return aabb.end.minus(aabb.start);
    }
};

pub const Vertex = extern struct {
    pos: Vec2,
    color0: Color,
};

pub const Color = extern struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    // zig fmt: off
    pub const white:      Color = .{ .r = 1,    .g = 1,    .b = 1,    .a = 1 };
    pub const black:      Color = .{ .r = 0,    .g = 0,    .b = 0,    .a = 1 };
    pub const red:        Color = .{ .r = 1,    .g = 0,    .b = 0,    .a = 1 };
    pub const green:      Color = .{ .r = 0,    .g = 1,    .b = 0,    .a = 1 };
    pub const blue:       Color = .{ .r = 0,    .g = 0,    .b = 1,    .a = 1 };
    pub const yellow:     Color = .{ .r = 1,    .g = 1,    .b = 0,    .a = 1 };
    pub const cyan:       Color = .{ .r = 0,    .g = 1,    .b = 1,    .a = 1 };
    pub const magenta:    Color = .{ .r = 1,    .g = 0,    .b = 1,    .a = 1 };
    pub const orange:     Color = .{ .r = 1,    .g = 0.5,  .b = 0,    .a = 1 };
    pub const purple:     Color = .{ .r = 0.5,  .g = 0,    .b = 0.5,  .a = 1 };
    pub const gray:       Color = .{ .r = 0.5,  .g = 0.5,  .b = 0.5,  .a = 1 };
    pub const light_gray: Color = .{ .r = 0.75, .g = 0.75, .b = 0.75, .a = 1 };
    pub const dark_gray:  Color = .{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1 };
    pub const brown:      Color = .{ .r = 0.6,  .g = 0.4,  .b = 0.2,  .a = 1 };
    pub const pink:       Color = .{ .r = 1,    .g = 0.75, .b = 0.8,  .a = 1 };
    pub const lime:       Color = .{ .r = 0.75, .g = 1,    .b = 0,    .a = 1 };
    pub const teal:       Color = .{ .r = 0,    .g = 0.5,  .b = 0.5,  .a = 1 };
    pub const navy:       Color = .{ .r = 0,    .g = 0,    .b = 0.5,  .a = 1 };
    // zig fmt: on
};

pub fn drawRect(s2d: *Sokol2d, aabb: AABB, color: Color) void {
    s2d.drawRectGradient(aabb, color, color, .horisontal);
}

pub fn drawRectGradient(s2d: *Sokol2d, aabb: AABB, color1: Color, color2: Color, orientation: enum { horisontal, vertical }) void {
    const top_left = aabb.start;
    const top_right: Vec2 = .{
        .x = aabb.start.x,
        .y = aabb.end.y,
    };
    const bottom_left: Vec2 = .{
        .x = aabb.end.x,
        .y = aabb.start.y,
    };
    const bottom_right = aabb.end;
    const coords: [6]Vertex = if (orientation == .horisontal) .{
        .{ .pos = top_right, .color0 = color1 },
        .{ .pos = top_left, .color0 = color1 },
        .{ .pos = bottom_left, .color0 = color2 },
        .{ .pos = top_right, .color0 = color1 },
        .{ .pos = bottom_left, .color0 = color2 },
        .{ .pos = bottom_right, .color0 = color2 },
    } else .{
        .{ .pos = top_right, .color0 = color2 },
        .{ .pos = top_left, .color0 = color1 },
        .{ .pos = bottom_left, .color0 = color1 },
        .{ .pos = top_right, .color0 = color2 },
        .{ .pos = bottom_left, .color0 = color1 },
        .{ .pos = bottom_right, .color0 = color2 },
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
        .vertecies = try .initCapacity(gpa, max_vertecies),
        .viewport = .{ .start = .zero, .end = .zero },
        .vertex_buffer = sokol.gfx.makeBuffer(.{
            .type = .VERTEXBUFFER,
            .usage = .DYNAMIC,
            .label = "sokol2d vertex buffer",
            .size = max_vertecies * @sizeOf(Vertex),
        }),
        .projection = .identity,
    };
}

pub fn flush(s2d: *Sokol2d) void {
    if (s2d.vertecies.items.len == 0) return;

    const viewport_size = s2d.viewport.size();

    sokol.gfx.applyViewport(
        @intFromFloat(s2d.viewport.start.x),
        @intFromFloat(s2d.viewport.start.y),
        @intFromFloat(viewport_size.x),
        @intFromFloat(viewport_size.y),
        true,
    );

    sokol.gfx.applyPipeline(s2d.pipeline);

    for (s2d.vertecies.items) |*vertex| {
        vertex.pos = s2d.projection.timesPoint(vertex.pos);
    }
    sokol.gfx.updateBuffer(s2d.vertex_buffer, sokol.gfx.asRange(s2d.vertecies.items));

    var bindings: sokol.gfx.Bindings = .{};
    bindings.vertex_buffers[0] = s2d.vertex_buffer;

    sokol.gfx.applyBindings(bindings);
    sokol.gfx.draw(0, @intCast(s2d.vertecies.items.len), 1);

    s2d.vertecies.clearRetainingCapacity();
}

const BeginConfig = struct {
    /// Area on screen/texture where to draw
    viewport: AABB,

    coordinates: AABB,
};

pub fn begin(s2d: *Sokol2d, config: BeginConfig) void {
    const scale_vec = config.coordinates.size();
    const translate: Mat2x3 = .translation(config.coordinates.start.negated());
    const scale: Mat2x3 = .scale(.{
        .x = 1 / scale_vec.x,
        .y = 1 / scale_vec.y,
    });
    s2d.projection = scale.times(translate);

    s2d.viewport = config.viewport;
}

pub fn deinit(s2d: *Sokol2d, gpa: std.mem.Allocator) void {
    sokol.gfx.destroyBuffer(s2d.vertex_buffer);
    sokol.gfx.destroyPipeline(s2d.pipeline);
    s2d.vertecies.deinit(gpa);

    log.info("deinit", .{});
}
