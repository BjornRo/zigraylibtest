const Self = @This();

ptr: *anyopaque,
drawFn: *const fn (*anyopaque) void,
updateFn: *const fn (*anyopaque) void,

pub fn init(impl: anytype) Self {
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

pub fn draw(self: *const Self) void {
    self.drawFn(self.ptr);
}

pub fn update(self: *const Self) void {
    self.updateFn(self.ptr);
}
