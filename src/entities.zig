const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const Controller = @import("controller.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

pub const Player = struct {
    position: Vec3,
    velocity: Vec3,
    speed: f32,
    camera: Controller.Camera,
    controller: *const Controller.ControllerFunc,

    const Self = @This();

    pub fn init(position: Vec3, speed: f32, controller: Controller.ControllerFunc) Self {
        return .{
            .position = position,
            .speed = speed,
            .camera = .{ .direction = Vec3.init(1, 0, 0), .yaw = 0, .pitch = 0 },
            .velocity = Vec3.init(0, 0, 0),
            .controller = controller,
        };
    }

    pub fn update(self: *Self, delta_time: f32) void {
        self.controller(&self.position, &self.velocity, &self.camera, self.speed, delta_time);
    }
};
