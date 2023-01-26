const std = @import("std");
const zap = @import("zap");

const fs = std.fs;
const cwd = fs.cwd();
const b64 = std.base64;
const b64_decoder = b64.standard.Decoder;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

var temp_buffer: [100]u8 = undefined;

const ImageData = struct {
    imageData: []const u8,
    foldername: []const u8,
    filename: []const u8,
    ext: []const u8,
};

fn onRequest(r: zap.SimpleRequest) void {
    if (std.mem.eql(u8, r.method.?, "POST")) {
        const body_str = r.body orelse "";
        var stream = std.json.TokenStream.init(body_str);
        const parsed = std.json.parse(ImageData, &stream, .{
            .allocator = allocator
        }) catch undefined;
        std.debug.print("\n→ {s}.{s}", .{ parsed.filename, parsed.ext });
        
        const schema = "data:image/octet-stream;base64,";
        const data_str = parsed.imageData[schema.len..];
        var decoded_length = b64_decoder.calcSizeForSlice(data_str) catch return;
        var data_decoded: []u8 = allocator.alloc(u8, decoded_length) catch return;
        b64_decoder.decode(data_decoded, data_str) catch return;

        const subpath = std.fmt.bufPrintZ(&temp_buffer,
                                          "./imgdata/{s}/",
                                          .{ parsed.foldername }) catch return;
        cwd.makePath(subpath) catch return;

        const filename_ext = std.fmt.bufPrintZ(&temp_buffer,
                                               "{s}/{s}.{s}",
                                               .{ subpath,
                                                 parsed.filename,
                                                 parsed.ext }) catch return;

        const out_file = cwd.createFile(filename_ext, .{ .read = false }) catch return;
        out_file.writeAll(data_decoded) catch return;
        defer out_file.close();
        var json_to_send: []const u8 =
            \\{ "succes": true }
        ;
        r.setHeader("Access-Control-Allow-Origin", "*");
        r.setContentType(.JSON);
        _ = r.sendJson(json_to_send);
    }
}

pub fn main() !void {
    var listener = zap.SimpleHttpListener.init(.{
        .port = 3000,
        .on_request = onRequest,
        .log = false,
    });
    try listener.listen();
    std.debug.print(
        \\ → Listening on http://0.0.0.0:3000
    , .{});
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
