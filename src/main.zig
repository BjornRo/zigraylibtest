const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("rcamera.zig");
const debug = @import("debug.zig");
const Entities = @import("entities.zig");
const Controller = @import("controller.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

var prng = std.Random.DefaultPrng.init(0);
const rand = prng.random();

const screen_width = 800;
const screen_height = 450;

const GameState = enum { MainMenu, Playing };

fn drawMainMenu(state: *GameState) void {
    const BUTTON_WIDTH = 200;
    const BUTTON_HEIGHT = 50;
    const btn_x = (screen_width - BUTTON_WIDTH) / 2;
    const btn_y = (screen_height - BUTTON_HEIGHT) / 2;
    const mouse = rl.getMousePosition();
    const hovering = rl.checkCollisionPointRec(mouse, .{
        .x = @floatFromInt(btn_x),
        .y = @floatFromInt(btn_y),
        .width = BUTTON_WIDTH,
        .height = BUTTON_HEIGHT,
    });
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.sky_blue);

    if (hovering) {
        rl.drawRectangle(btn_x, btn_y, BUTTON_WIDTH, BUTTON_HEIGHT, Color.dark_gray);
        if (rl.isMouseButtonPressed(.left)) {
            state.* = GameState.Playing;
        }
    } else {
        rl.drawRectangle(btn_x, btn_y, BUTTON_WIDTH, BUTTON_HEIGHT, Color.gray);
    }

    rl.drawText("Start", btn_x + 60, btn_y + 15, 20, Color.black);
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    rl.initWindow(screen_width, screen_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(10);

    var state: GameState = .MainMenu;

    while (!rl.windowShouldClose()) {
        switch (state) {
            .MainMenu => {
                drawMainMenu(&state);
            },
            .Playing => {
                try run(allocator);
                state = .MainMenu;
            },
        }
    }
}

// fn update() void {
//     for (active_state.entities) |e| {
//         e.update();
//     }
// }

// fn render() void {
//     for (active_state.entities) |e| {
//         e.draw();
//     }
// }

fn run(allocator: Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const max_columns = 20;
    // const width = rl.getScreenWidth();
    // const height = rl.getScreenHeight();
    const fwidth: f32 = @floatFromInt(rl.getScreenWidth());
    const fheight: f32 = @floatFromInt(rl.getScreenHeight());

    var camera = rl.Camera{
        .position = .{ .x = 0, .y = 2, .z = 4 },
        .target = .{ .x = 0, .y = 2, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 60,
        .projection = .perspective,
    };

    var player = Entities.Player.init(Vec3.init(0, 1, 0), 5, Controller.keyboard);

    const camera_mode: rl.CameraMode = .first_person;

    var heights: [max_columns]f32 = undefined;
    var positions: [max_columns]Vec3 = undefined;
    var colors: [max_columns]Color = undefined;

    for (0..max_columns) |i| {
        heights[i] = @floatFromInt(rand.intRangeAtMost(i8, 1, 12));
        positions[i] = Vec3.init(
            @floatFromInt(rand.intRangeAtMost(i8, -15, 15)),
            heights[i] / 2.0,
            @floatFromInt(rand.intRangeAtMost(i8, -15, 15)),
        );
        colors[i] = Color.init(rand.intRangeAtMost(u8, 20, 255), rand.intRangeAtMost(u8, 10, 55), 30, 255);
    }

    rl.disableCursor();
    defer rl.enableCursor();

    rl.setTargetFPS(60);

    while (true) {
        defer _ = arena.reset(.retain_capacity);
        if (rl.isKeyPressed(.escape)) {
            rl.beginDrawing();
            rl.endDrawing();
            break;
        }

        const delta_time = rl.getFrameTime();
        player.update(delta_time);

        camera.position = player.position;
        camera.position.y += 1.5;
        camera.target = Vec3.init(player.position.x, player.position.y + 1.5, player.position.z - 1);

        rl.updateCamera(&camera, camera_mode);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(Color.ray_white);
        {
            rl.beginMode3D(camera);
            defer rl.endMode3D();

            rl.drawPlane(Vec3.init(0, 0, 0), Vec2.init(32, 32), Color.light_gray); // Draw ground
            rl.drawCube(Vec3.init(-16, 2.5, 0), 1, 5, 32, Color.blue); // Draw a blue wall
            rl.drawCube(Vec3.init(16, 2.5, 0), 1, 5, 32, Color.lime); // Draw a green wall
            rl.drawCube(Vec3.init(0, 2.5, 16), 32, 5, 1, Color.gold); // Draw a yellow wall

            for (0..max_columns) |i| {
                rl.drawCube(positions[i], 2, heights[i], 2, colors[i]);
                rl.drawCubeWires(positions[i], 2, heights[i], 2, Color.maroon);

                if (camera_mode == .third_person) {
                    rl.drawCube(camera.target, 0.5, 0.5, 0.5, Color.purple);
                    rl.drawCubeWires(camera.target, 0.5, 0.5, 0.5, Color.dark_purple);
                }
            }
        }

        // Crosshair
        // rl.drawLine(@divFloor(width, 2) - 10, @divFloor(height, 2), @divFloor(width, 2) + 10, @divFloor(height, 2), Color.green);
        // rl.drawLine(@divFloor(width, 2), @divFloor(height, 2) - 10, @divFloor(width, 2), @divFloor(height, 2) + 10, Color.green);
        // rl.drawLineEx(.{ .x = fwidth / 2 - 12, .y = fheight / 2 }, .{ .x = fwidth / 2 + 12, .y = fheight / 2 }, 3, Color.green);
        // rl.drawLineEx(.{ .x = fwidth / 2, .y = fheight / 2 - 12 }, .{ .x = fwidth / 2, .y = fheight / 2 + 12 }, 3, Color.green);
        rl.drawLineEx(Vec2.init(fwidth / 2 - 12, fheight / 2), Vec2.init(fwidth / 2 - 4, fheight / 2), 2, Color.green);
        rl.drawLineEx(Vec2.init(fwidth / 2 + 4, fheight / 2), Vec2.init(fwidth / 2 + 12, fheight / 2), 2, Color.green);
        rl.drawLineEx(Vec2.init(fwidth / 2, fheight / 2 - 12), Vec2.init(fwidth / 2, fheight / 2 - 4), 2, Color.green);
        rl.drawLineEx(Vec2.init(fwidth / 2, fheight / 2 + 4), Vec2.init(fwidth / 2, fheight / 2 + 12), 2, Color.green);

        try debug.debug_window(arena_alloc, camera_mode, camera);
    }
}
