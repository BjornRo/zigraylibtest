const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

const World_Up: Vec3 = Vec3.init(0, 1, 0);
const Deg2Rad = math.degreesToRadians;

pub const ControllerFunc = fn (position: *Vec3, velocity: *Vec3, camera: *Camera, speed: f32, delta_time: f32) void;

pub const Camera = struct {
    direction: Vec3,
    yaw: f32,
    pitch: f32,
};

pub fn keyboardMouse(
    position: *Vec3,
    velocity: *Vec3,
    camera: *Camera,
    speed: f32,
    delta_time: f32,
) void {
    // Mouse
    const sensitivity: f32 = 0.1;
    const mouse_delta: Vec2 = rlm.vector2Multiply(
        Vec2.init(sensitivity, sensitivity),
        rl.getMouseDelta(),
    );

    camera.yaw = @mod(camera.yaw + mouse_delta.x, 360);
    camera.pitch = rlm.clamp(camera.pitch - mouse_delta.y, -89, 89);

    const yaw = Deg2Rad(camera.yaw);
    const pitch = Deg2Rad(camera.pitch);

    camera.direction = Vec3.init(
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch),
        math.sin(yaw) * math.cos(pitch),
    );

    // Keyboard
    const acceleration = speed * delta_time * 10;
    const damping: f32 = 0.9;

    const forward = Vec3.init(math.cos(yaw), 0, math.sin(yaw));
    const right = Vec3.init(-forward.z, 0, forward.x);

    // Apply movement based on key inputs
    var movement = Vec3.init(0, 0, 0);
    // const forward_scale = rlm.vector3Scale(forward, speed_delta);
    // const right_scale = rlm.vector3Scale(right, speed_delta);
    if (rl.isKeyDown(.w)) movement = movement.add(forward);
    if (rl.isKeyDown(.s)) movement = movement.subtract(forward);
    if (rl.isKeyDown(.a)) movement = movement.subtract(right);
    if (rl.isKeyDown(.d)) movement = movement.add(right);

    if (movement.equals(Vec3.zero()) != 0) {
        movement = movement.normalize();
    }

    velocity.x += movement.x * acceleration;
    velocity.z += movement.z * acceleration;

    velocity.x *= damping;
    velocity.z *= damping;

    if (rl.isKeyPressed(.space)) {
        velocity.y = 14;
    } else {
        velocity.y -= 9.8 * 0.1;
        // velocity.y /= 1.5;
    }

    position.* = position.add(velocity.multiply(Vec3.init(delta_time, delta_time, delta_time)));

    // TODO collision test, to be moved
    if (position.y <= 1) {
        position.y = 1;
        velocity.y = 0;
    }
}
