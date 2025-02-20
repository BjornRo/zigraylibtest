const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

pub fn debug_window(arena_alloc: Allocator, camera_mode: rl.CameraMode, camera: rl.Camera) !void {
    // rl.drawRectangle(5, 5, 330, 100, Color.fade(Color.sky_blue, 0.5));
    // rl.drawRectangleLines(5, 5, 330, 100, Color.blue);
    // rl.drawText("Camera controls:", 15, 15, 10, Color.black);
    // rl.drawText("- Move keys: W, A, S, D", 15, 30, 10, Color.black);
    // rl.drawText("- Look around: arrow keys or mouse", 15, 45, 10, Color.black);
    // rl.drawText("- Camera mode keys: 1, 2, 3, 4", 15, 60, 10, Color.black);
    // rl.drawText("- Zoom keys: num-plus, num-minus or mouse scroll", 15, 75, 10, Color.black);
    // rl.drawText("- Camera projection key: P", 15, 90, 10, Color.black);

    rl.drawRectangle(600, 5, 195, 115, Color.fade(Color.sky_blue, 0.5));
    rl.drawRectangleLines(600, 5, 195, 115, Color.blue);

    rl.drawText("Camera status:", 610, 15, 10, Color.black);
    rl.drawText(blk: {
        const text = switch (camera_mode) {
            .free => "FREE",
            .first_person => "FIRST_PERSON",
            .third_person => "THIRD_PERSON",
            .orbital => "ORBITAL",
            .custom => "CUSTOM",
        };
        break :blk try std.fmt.allocPrintZ(arena_alloc, "- Mode: {s}", .{text});
    }, 610, 30, 10, Color.black);
    rl.drawText(blk: {
        const text = if (camera.projection == .perspective) "PERSPECTIVE" else "ORTHOGRAPHIC";
        break :blk try std.fmt.allocPrintZ(arena_alloc, "- Projection: {s}", .{text});
    }, 610, 45, 10, Color.black);
    rl.drawText(try std.fmt.allocPrintZ(
        arena_alloc,
        "- Position: ({d:.3}, {d:.3}, {d:.3})",
        .{ camera.position.x, camera.position.y, camera.position.z },
    ), 610, 60, 10, Color.black);
    rl.drawText(try std.fmt.allocPrintZ(
        arena_alloc,
        "- Target: ({d:.3}, {d:.3}, {d:.3})",
        .{ camera.target.x, camera.target.y, camera.target.z },
    ), 610, 75, 10, Color.black);
    rl.drawText(try std.fmt.allocPrintZ(
        arena_alloc,
        "- Up: ({d:.3}, {d:.3}, {d:.3})",
        .{ camera.up.x, camera.up.y, camera.up.z },
    ), 610, 90, 10, Color.black);
    rl.drawText(try std.fmt.allocPrintZ(
        arena_alloc,
        "- Frame time: {d:.3}ms",
        .{rl.getFrameTime() * 1000},
    ), 610, 105, 10, Color.black);
}
