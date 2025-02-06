const std = @import("std");
const rl = @import("raylib");
const math = std.math;
const rlm = rl.math;
const rlc = rl.Color;
const Vec2 = rl.Vector2;

const screen_width = 800;
const screen_height = 450;
var active_state: State = undefined;

const GameState = enum { MainMenu, Playing };

pub fn main() anyerror!void {
    rl.initWindow(screen_width, screen_height, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state: GameState = .MainMenu;

    while (!rl.windowShouldClose()) {
        switch (state) {
            .MainMenu => {
                drawMainMenu(&state);
            },
            .Playing => {
                run();
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
        rl.drawRectangle(btn_x, btn_y, BUTTON_WIDTH, BUTTON_HEIGHT, rlc.dark_gray);
        if (rl.isMouseButtonPressed(.left)) {
            state.* = GameState.Playing;
        }
    } else {
        rl.drawRectangle(btn_x, btn_y, BUTTON_WIDTH, BUTTON_HEIGHT, rlc.gray);
    }

    rl.drawText("Start", btn_x + 60, btn_y + 15, 20, rlc.black);
}

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

const Triangle = struct {
    points: []const Vec2,
    pos: Vec2,
    rot: f32,

    const Self = @This();
    pub fn init(points: []const Vec2, pos: Vec2, rot: f32) Self {
        return .{ .points = points, .pos = pos, .rot = rot };
    }

    pub fn draw(self: *Self) void {
        drawLines(self.pos, 60, self.rot, self.points, 5);
    }

    pub fn update(self: *Self) void {
        self.rot += math.tau * 0.01;
        self.rot = @mod(self.rot, math.pi * 2);
    }
};

fn update() void {
    for (active_state.entities) |e| {
        e.update();
    }
}

fn render() void {
    for (active_state.entities) |e| {
        e.draw();
    }
}

fn run() void {
    const width: f32 = @floatFromInt(rl.getScreenWidth());
    const height: f32 = @floatFromInt(rl.getScreenHeight());

    var triangle = Triangle.init(
        &.{
            Vec2.init(0, -0.5),
            Vec2.init(-0.5, 0.5),
            Vec2.init(0.5, 0.5),
        },
        .{ .x = width * 0.5, .y = height * 0.5 },
        0.0,
    );
    var triangle2 = Triangle.init(
        &.{
            Vec2.init(0, -0.5),
            Vec2.init(-0.5, 0.5),
            Vec2.init(0.5, 0.5),
        },
        .{ .x = width * 0.1, .y = height * 0.1 },
        0.0,
    );

    active_state = State{ .entities = &.{
        EntityInterface.init(&triangle),
        EntityInterface.init(&triangle2),
    } };

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rlc.white);

        render();
    }
}

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
