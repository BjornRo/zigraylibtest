const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

const EntityInterface = struct {
    ptr: *anyopaque,
    drawFn: *const fn (*anyopaque) void,
    updateFn: *const fn (*anyopaque) void,

    pub fn init(impl: anytype) EntityInterface {
        const Wrapper = struct {
            fn draw(ptr: *anyopaque) void {
                const self: @TypeOf(impl) = @ptrCast(@alignCast(ptr));
                self.draw();
            }
            fn update(ptr: *anyopaque) void {
                const self: @TypeOf(impl) = @ptrCast(@alignCast(ptr));
                self.update();
            }
        };

        return .{
            .ptr = @ptrCast(@alignCast(impl)),
            .drawFn = Wrapper.draw,
            .updateFn = Wrapper.update,
        };
    }

    pub fn draw(self: *const EntityInterface) void {
        self.drawFn(self.ptr);
    }

    pub fn update(self: *const EntityInterface) void {
        self.updateFn(self.ptr);
    }
};

const State = struct {
    entities: []const EntityInterface,
};

const Cube = struct {
    pos: Vec3,
    dim: f32,

    const Self = @This();
    pub fn init(pos: Vec3, dim: f32) Self {
        return .{ .pos = pos, .dim = dim };
    }

    pub fn draw(self: *Self) void {
        rl.drawCube(self.pos, self.dim, self.dim, self.dim, rlc.dark_green);
    }

    pub fn update(self: *Self) void {
        _ = self;
        // self.rot += math.tau * 0.01;
        // self.rot = @mod(self.rot, math.pi * 2);
    }
};
