const std = @import("std");
const Io = std.Io;

fn readUpTo(reader: anytype, dest: []u8) !usize {
    var total_read: usize = 0;
    while (total_read < dest.len) {
        var slices = [_][]u8{dest[total_read..]};
        const n = reader.readVec(&slices) catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        if (n == 0) break;
        total_read += n;
    }
    return total_read;
}

pub fn loadTga(
    allocator: std.mem.Allocator,
    io: anytype,
    filename: []const u8,
    stdout_writer: anytype,
    stderr_writer: anytype,
) ![]u8 {
    const cwd = Io.Dir.cwd();
    // Note: C++ uses "Could not open file" followed directly by the filename with no space.
    var file = cwd.openFile(io, filename, .{ .mode = .read_only }) catch |err| {
        stderr_writer.print("Could not open file{s}.\n", .{filename}) catch {};
        return err;
    };
    defer file.close(io);

    var file_buffer: [1024]u8 = undefined;
    var file_reader: Io.File.Reader = .init(file, io, &file_buffer);
    const reader = &file_reader.interface;

    var header: [18]u8 = undefined;
    const bytes_read = try readUpTo(reader, &header);
    if (bytes_read < 18) {
        stderr_writer.print("{s} is an invalid TGA file.\n", .{filename}) catch {};
        return error.InvalidTgaHeader;
    }

    const correct_signature = [_]u8{ 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    if (!std.mem.eql(u8, header[0..12], &correct_signature)) {
        stderr_writer.print("{s} is an invalid TGA file.\n", .{filename}) catch {};
        return error.InvalidSignature;
    }

    const width = std.mem.readInt(u16, header[12..14], .little);
    const height = std.mem.readInt(u16, header[14..16], .little);
    const bpp_raw = std.mem.readInt(u16, header[16..18], .little);
    const bpp = bpp_raw / 8;

    stdout_writer.print("{d}\n", .{bpp}) catch {};

    const data_length = @as(usize, width) * height * bpp;
    const data = allocator.alloc(u8, data_length) catch |err| {
        stderr_writer.print("Could not allocate memory for the TGA image.\n", .{}) catch {};
        return err;
    };
    errdefer allocator.free(data);

    stdout_writer.print("{d} bytes allocated\n", .{data_length}) catch {};

    // C++ code fread-s the file into the allocated buffer. If width*height*bpp
    // is larger than the file, it reads what's there and leaves the rest.
    _ = try readUpTo(reader, data);

    return data;
}

pub fn BGRtoRGB(data: []u8) bool {
    const rgb_length = 3;
    var i: usize = 0;
    while (i < data.len) : (i += rgb_length) {
        if (i + 2 < data.len) {
            std.mem.swap(u8, &data[i], &data[i + 2]);
        }
    }
    return true;
}

pub fn BGRtoBGRA(data: []u8) bool {
    const rgb_length = 3;
    var i: usize = 0;
    while (i < data.len) : (i += rgb_length) {
        if (i + 2 < data.len) {
            std.mem.swap(u8, &data[i], &data[i + 2]);
        }
    }
    return true;
}
