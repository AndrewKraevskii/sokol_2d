const std = @import("std");
const Sokol2d = @import("sokol_2d");
const sokol = @import("sokol");

var state: struct {
    sokol_2d: Sokol2d,
    gpa: std.mem.Allocator,
} = undefined;

fn init() callconv(.c) void {
    sokol.gfx.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    std.log.info("make attachments", .{});
    state.sokol_2d = Sokol2d.init(state.gpa) catch {
        std.log.err("OOM", .{});
        sokol.app.quit();
        return;
    };
}
const white: [4]f32 = .{ 1, 1, 1, 1 };
const red: [4]f32 = .{ 1, 0, 0, 1 };
const yellow: [4]f32 = .{ 1, 1, 0, 0.1 };

fn frame() callconv(.c) void {
    const width: u31 = @intCast(sokol.app.width());
    const height: u31 = @intCast(sokol.app.height());

    state.sokol_2d.begin(width, height);
    state.sokol_2d.drawLine(.{ .x = 0, .y = 0 }, .{ .x = 1, .y = 1 }, 0.01, red);
    state.sokol_2d.drawCircle(.{ .x = 0.5, .y = 0.5 }, 0.5, yellow, 30);
    state.sokol_2d.drawRectGradient(0, 0, 0.3, 0.2, red, yellow, .horisontal);

    {
        sokol.gfx.beginPass(.{
            .swapchain = sokol.glue.swapchain(),
        });
        defer sokol.gfx.endPass();

        state.sokol_2d.flush();
    }
    sokol.gfx.commit();
}

fn event(e: [*c]const sokol.app.Event) callconv(.c) void {
    switch (e.*.type) {
        .KEY_DOWN => {
            if (e.*.key_code == .ESCAPE) {
                sokol.app.requestQuit();
            }
        },
        else => {},
    }
}

fn deinit() callconv(.c) void {
    state.sokol_2d.deinit();
}

pub fn main() !void {
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    state.gpa = gpa_state.allocator();

    sokol.app.run(.{
        .init_cb = &init,
        .frame_cb = &frame,
        .cleanup_cb = &deinit,
        .event_cb = &event,
    });
}
