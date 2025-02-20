const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

pub const Player = struct {
    position: Vec3,
    velocity: Vec3,
    speed: f32,
    controller: *const ControllerType,

    const ControllerType = fn (position: *Vec3, velocity: *Vec3, speed: f32, delta_time: f32) void;
    const Self = @This();

    pub fn init(position: Vec3, speed: f32, controller: ControllerType) Self {
        return .{
            .position = position,
            .speed = speed,
            .controller = controller,
            .velocity = Vec3.init(0, 0, 0),
        };
    }

    pub fn update(self: *Self, delta_time: f32) void {
        self.controller(&self.position, &self.velocity, self.speed, delta_time);
    }
};
