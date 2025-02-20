const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

pub fn keyboard(position: *Vec3, velocity: *Vec3, speed: f32, delta_time: f32) void {
    const speed_delta = speed * delta_time;
    if (rl.isKeyDown(.w)) position.z -= speed_delta;
    if (rl.isKeyDown(.s)) position.z += speed_delta;
    if (rl.isKeyDown(.a)) position.x -= speed_delta;
    if (rl.isKeyDown(.d)) position.x += speed_delta;

    if (rl.isKeyPressed(.space)) {
        velocity.y = 2;
    } else {
        velocity.y -= 9.8 * delta_time;
        velocity.y /= 1.5;
    }

    position.y += velocity.y;

    if (position.y <= 1) {
        position.y = 1;
        velocity.y = 0;
    }
}
