const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = rl.Color;
const Vec2 = rl.Vector2;

fn drawLines(origin: Vec2, scale: f32, rotation: f32, points: []const Vec2, thickness: f32) void {
    const Transformer = struct {
        origin: Vec2,
        scale: f32,
        rotation: f32,

        fn apply(self: @This(), point: Vec2) Vec2 {
            return rlm.vector2Add(
                rlm.vector2Scale(rlm.vector2Rotate(point, self.rotation), self.scale),
                self.origin,
            );
        }
    };

    const t = Transformer{ .origin = origin, .scale = scale, .rotation = rotation };

    for (points, 0..) |p, i| {
        rl.drawLineEx(
            t.apply(p),
            t.apply(points[(i + 1) % points.len]),
            thickness,
            rlc.orange,
        );
    }
}

const State = struct {
    triangle: Triangle,
};

const Triangle = struct {
    // pos: Vec2,
    rot: f32,
};

fn update() void {
    state.triangle.rot += math.tau * 0.01;
    state.triangle.rot = @mod(state.triangle.rot, math.pi * 2);
    // std.debug.print("{d}\n", .{state.triangle.rot});
}

fn render() void {
    const width: f32 = @floatFromInt(rl.getScreenWidth());
    const height: f32 = @floatFromInt(rl.getScreenHeight());
    drawLines(
        .{ .x = width * 0.5, .y = height * 0.5 },
        60,
        state.triangle.rot,
        &.{
            Vec2.init(0, -0.5),
            Vec2.init(-0.5, 0.5),
            Vec2.init(0.5, 0.5),
        },
        5,
    );
}

var state: State = undefined;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    state = State{ .triangle = .{ .rot = 0.0 } };

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        update();
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        render();
        //----------------------------------------------------------------------------------
    }
}
