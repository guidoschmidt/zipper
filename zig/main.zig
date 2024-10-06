const std = @import("std");
const tk = @import("tokamak");
const zstbi = @import("zstbi");

const Allocator = std.mem.Allocator;
const fs = std.fs;
const cwd = fs.cwd();
const b64 = std.base64;
const b64_decoder = b64.standard.Decoder;

var temp_buffer: [256]u8 = undefined;

pub const ImageData = struct {
    frame_num: usize,
    width: i32,
    height: i32,
    imageData: []u8,
    foldername: []const u8,
    filename: []const u8,
    ext: []const u8,
};

fn storeImage(allocator: Allocator, image_data: ImageData) !void {
    const subpath = try std.fmt.bufPrintZ(&temp_buffer, "./imgdata/{s}/", .{ image_data.foldername });
    try cwd.makePath(subpath);
    const output_file = std.fmt.allocPrintZ(allocator, "{s}/{s}_{d:0>8}.{s}", .{
        subpath, image_data.filename, image_data.frame_num, image_data.ext,
    }) catch {
        @panic("Could not allocPrint!");
    };
    defer allocator.free(output_file);

    const img = zstbi.Image {
        .width = @intCast(image_data.width),
        .height = @intCast(image_data.height),
        .num_components = 4,
        .data = image_data.imageData[0..],
        .bytes_per_row = @intCast(image_data.width),
        .bytes_per_component = 1,
        .is_hdr = false,
    };
    zstbi.Image.writeToFile(img, output_file, .png) catch |err| {
        std.log.err("{any}", .{ err });
    };

    std.debug.print("\n>>> {s}", .{ output_file });

    // const schema = "data:image/png;base64,";
    // const data_str = image_data.imageData[schema.len..];
    // const decoded_length = try b64_decoder.calcSizeForSlice(data_str);
    // const data_decoded: []u8 = try allocator.alloc(u8, decoded_length);
    // defer allocator.free(data_decoded);
    // try b64_decoder.decode(data_decoded, data_str);
    // try out_file.writeAll(data_decoded);
}

fn runServer(port: u16) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    zstbi.init(allocator);
    zstbi.setFlipVerticallyOnWrite(true);
    defer zstbi.deinit();

    var server = try tk.Server.start(allocator, handler, .{ .port = port });
    server.wait();
}

pub fn main() !void {
    const port: u16 = 8000;
    std.debug.print("\nRunnig tokamak\n>>> http://127.0.0.1:{d}", .{ port });
    std.debug.print("\n{any}", .{ std.json.default_max_value_len });
    // tk.monitor(.{
    //     .{ "server", &runServer, .{ port } },
    //     // @TODO test worker support
    //     // .{ "worker", &runWorker, .{} },
    // });
    try runServer(port);
}

const handler = tk.chain(.{
    tk.cors(),
    tk.group("/", tk.router(api)),
    tk.send(error.NotFound),
});

const api = struct {
    pub fn @"POST /"(req: *tk.Request, allocator: std.mem.Allocator, image_data: ImageData) !u32 {
        _ = req;
        try storeImage(allocator, image_data);
        return 200;
    }
};
