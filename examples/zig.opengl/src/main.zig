const std = @import("std");
const zglfw = @import("zglfw");
const gl = @import("gl");
const zipper = @import("zipper");

fn getProcAddress(prefixed_name: [*:0]const u8) ?gl.PROC {
    return @alignCast(zglfw.getProcAddress(std.mem.span(prefixed_name)));
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var procs: gl.ProcTable = undefined;

    try zglfw.init();
    const window = try zglfw.Window.create(300, 300, "zipper-opengl", null);
    defer window.destroy();
    zglfw.makeContextCurrent(window);

    if (!procs.init(getProcAddress)) return error.InitFailed;
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    const size = window.getFramebufferSize();
    const width = size[0];
    const height = size[1];

    var r: f32 = 0.0;
    var g: f32 = 0.0;
    var b: f32 = 0.0;

    var is_recording = false;
    var frame: usize = 0;
    var pixels: []u8 = try allocator.alloc(u8, @as(usize, @intCast(width)) * @as(usize, @intCast(height)) * 4);
    try zipper.init(allocator, "zig-opengl", "zipper-examples");
    defer zipper.deinit();

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        gl.ClearColor(r, g, b, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        if (window.getKey(.r) == .press) {
            is_recording = true;
        }
        if (window.getKey(.s) == .press) {
            is_recording = false;
        }

        if (is_recording) {
            std.debug.print("\nSaving frame {d}...", .{ frame });
            gl.ReadPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, @ptrCast(pixels[0..]));
            try zipper.putPixels(pixels[0..], width, height, frame);
            frame += 1;
        }

        zglfw.pollEvents();
        window.swapBuffers();

        r += 0.005;
        g += 0.007;
        b += 0.009;
        r = @mod(r, 1.0);
        g = @mod(g, 1.0);
        b = @mod(b, 1.0);
    }
}
