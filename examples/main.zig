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

fn frame() callconv(.c) void {
    const width: u31 = @intCast(sokol.app.width());
    const height: u31 = @intCast(sokol.app.height());

    const ratio = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));
    state.sokol_2d.begin(.{
        .viewport = .{
            .start = .zero,
            .end = .{
                .x = @floatFromInt(width),
                .y = @floatFromInt(height),
            },
        },
        .coordinates = .{
            .start = .{
                .x = -ratio,
                .y = -1,
            },
            .end = .{
                .x = ratio,
                .y = 1,
            },
        },
    });

    state.sokol_2d.drawRect(.{ .start = .{ .x = -1, .y = -1 }, .end = .{ .x = 1, .y = 1 } }, .dark_gray);
    state.sokol_2d.drawLine(.{ .x = -1, .y = -1 }, .{ .x = 1, .y = 1 }, 0.01, .red);
    state.sokol_2d.drawCircle(.zero, 0.1, .yellow, 30);
    state.sokol_2d.drawRectGradient(.fromCenterSize(.{ .x = 0, .y = 0 }, .{ .x = 0.3, .y = 0.1 }), .red, .yellow, .vertical);

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
    state.sokol_2d.deinit(state.gpa);
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
