const std = @import("std");
const tk = @import("tokamak");

const Allocator = std.mem.Allocator;
const fs = std.fs;
const cwd = fs.cwd();
const b64 = std.base64;
const b64_decoder = b64.standard.Decoder;

var temp_buffer: [100]u8 = undefined;

const ImageData = struct {
    imageData: []const u8,
    foldername: []const u8,
    filename: []const u8,
    ext: []const u8,
};

fn storeImage(allocator: Allocator, image_data: ImageData) !void {
    const subpath = try std.fmt.bufPrintZ(&temp_buffer, "./imgdata/{s}/", .{ image_data.foldername });
    try cwd.makePath(subpath);

    const filename_with_ext = try std.fmt.allocPrint(allocator, "{s}/{s}.{s}", .{
        subpath, image_data.filename, image_data.ext
    });
    defer allocator.free(filename_with_ext);

    const out_file = try cwd.createFile(filename_with_ext, .{ .read = false });
    defer out_file.close();


    const schema = "data:image/octet-stream;base64,";
    const data_str = image_data.imageData[schema.len..];
    const decoded_length = try b64_decoder.calcSizeForSlice(data_str);
    const data_decoded: []u8 = try allocator.alloc(u8, decoded_length);
    defer allocator.free(data_decoded);
    try b64_decoder.decode(data_decoded, data_str);

    try out_file.writeAll(data_decoded);

    std.debug.print("\r → Saving {s}/{s}.{s} …", .{ image_data.foldername, image_data.filename, image_data.ext });
}

pub fn main() !void {
    std.debug.print("\nRunnig tokamak", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var server = try tk.Server.start(allocator, handler, .{ .port = 8000 });
    server.wait();
}

const handler = tk.chain(.{
    tk.cors(),
    // tk.get("/", tk.send("zipper")),
    tk.group("/", tk.router(api)),
    tk.send(error.NotFound),
});

const api = struct {
    pub fn @"POST /"(allocator: std.mem.Allocator, image_data: ImageData) ![]const u8 {
        try storeImage(allocator, image_data);
        return std.fmt.allocPrint(allocator, "\n{any}", .{ image_data });
    }
};
