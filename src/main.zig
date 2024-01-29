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

fn onRequest(r: zap.Request) void {
    if (std.mem.eql(u8, r.method.?, "POST")) {
        const body_str = r.body orelse "";

        // var tokenizer = std.json.Scanner.initCompleteInput(allocator, body_str);
        // defer tokenizer.deinit();
        // const token = tokenizer.next();

        const parsed = std.json.parseFromSlice(ImageData, allocator, body_str, .{}) catch {
            return;
        };
        defer parsed.deinit();
        const result = parsed.value;

        std.debug.print("\r → Saving {s}/{s}.{s} …", .{ result.foldername, result.filename, result.ext });

        const schema = "data:image/octet-stream;base64,";
        const data_str = result.imageData[schema.len..];
        var decoded_length = b64_decoder.calcSizeForSlice(data_str) catch return;
        var data_decoded: []u8 = allocator.alloc(u8, decoded_length) catch return;
        b64_decoder.decode(data_decoded, data_str) catch return;

        const subpath = std.fmt.bufPrintZ(&temp_buffer, "./imgdata/{s}/", .{ result.foldername }) catch return;
        cwd.makePath(subpath) catch return;

        const filename_with_ext = std.fmt.allocPrint(allocator, "{s}/{s}.{s}", .{
            subpath, result.filename, result.ext
        }) catch unreachable;
        defer allocator.free(filename_with_ext);

        const out_file = cwd.createFile(filename_with_ext, .{ .read = false }) catch return;
        defer out_file.close();
        out_file.writeAll(data_decoded) catch return;

        var json_to_send: []const u8 =
            \\{ "succes": true }
        ;
        r.setHeader("Access-Control-Allow-Origin", "*") catch {
            return;
        };
        r.setContentType(.JSON) catch {
            return;
        };
        _ = r.sendJson(json_to_send) catch {
            return;
        };
    }
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = onRequest,
        .log = false,
    });
    try listener.listen();
    std.debug.print(
        \\ → Listening on http://0.0.0.0:3000
        \\
    , .{});
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
