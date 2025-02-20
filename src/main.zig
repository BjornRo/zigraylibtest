const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = @import("camera.zig");
const Color = rl.Color;
const Vec2 = rl.Vector2;
const Vec3 = rl.Vector3;

const screen_width = 800;
const screen_height = 450;

const GameState = enum { MainMenu, Playing };

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

    var prng = std.Random.DefaultPrng.init(0);
    const rand = prng.random();

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

    var camera_mode: rl.CameraMode = .first_person;

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

        if (rl.isKeyPressed(.one)) {
            camera_mode = .free;
            camera.up = .{ .x = 0, .y = 1, .z = 0 };
        }
        if (rl.isKeyPressed(.two)) {
            camera_mode = .first_person;
            camera.up = .{ .x = 0, .y = 1, .z = 0 };
        }
        if (rl.isKeyPressed(.three)) {
            camera_mode = .third_person;
            camera.up = .{ .x = 0, .y = 1, .z = 0 };
        }
        if (rl.isKeyPressed(.four)) {
            camera_mode = .orbital;
            camera.up = .{ .x = 0, .y = 1, .z = 0 };
        }

        if (rl.isKeyPressed(.p)) {
            switch (camera.projection) {
                .perspective => {
                    camera_mode = .third_person;
                    camera.position = .{ .x = 0, .y = 2, .z = -100 };
                    camera.target = .{ .x = 0, .y = 2, .z = 0 };
                    camera.up = .{ .x = 0, .y = 1, .z = 0 };
                    camera.projection = .orthographic;
                    camera.fovy = 20;
                    rlc.cameraYaw(&camera, std.math.degreesToRadians(-135), true);
                    rlc.cameraPitch(&camera, std.math.degreesToRadians(-45), true, true, true);
                },
                .orthographic => {
                    camera_mode = .third_person;
                    camera.position = .{ .x = 0, .y = 2, .z = 10 };
                    camera.target = .{ .x = 0, .y = 2, .z = 0 };
                    camera.up = .{ .x = 0, .y = 1, .z = 0 };
                    camera.projection = .perspective;
                    camera.fovy = 60;
                },
            }
        }

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

        rl.drawRectangle(5, 5, 330, 100, Color.fade(Color.sky_blue, 0.5));
        rl.drawRectangleLines(5, 5, 330, 100, Color.blue);

        rl.drawText("Camera controls:", 15, 15, 10, Color.black);
        rl.drawText("- Move keys: W, A, S, D", 15, 30, 10, Color.black);
        rl.drawText("- Look around: arrow keys or mouse", 15, 45, 10, Color.black);
        rl.drawText("- Camera mode keys: 1, 2, 3, 4", 15, 60, 10, Color.black);
        rl.drawText("- Zoom keys: num-plus, num-minus or mouse scroll", 15, 75, 10, Color.black);
        rl.drawText("- Camera projection key: P", 15, 90, 10, Color.black);

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
}
