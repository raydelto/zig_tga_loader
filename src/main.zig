const std = @import("std");
const tga_loader = @import("tga_loader.zig");
const graphics = @import("graphics.zig");
const c = @import("sdl2.zig");
const Io = std.Io;

fn loadData(surface: *c.SDL_Surface, myData: []const u8) void {
    var myDataIdx: usize = 0;
    var i: i32 = 0;
    while (i < graphics.SCREEN_HEIGHT) : (i += 1) {
        var j: i32 = 0;
        while (j < graphics.SCREEN_WIDTH) : (j += 1) {
            if (myDataIdx + 2 >= myData.len) return;
            const r = myData[myDataIdx];
            const g = myData[myDataIdx + 1];
            const b = myData[myDataIdx + 2];
            myDataIdx += 3;

            // In C++, the channels were loaded sequentially into a 4-byte buffer:
            // color[0] = *myData++, color[1] = *myData++, color[2] = *myData++, color[3] = 0
            // When cast to (unsigned int*), color[0] is the least significant byte on little-endian.
            const color_val = @as(u32, r) | (@as(u32, g) << 8) | (@as(u32, b) << 16);
            graphics.drawPixel(surface, j, i, color_val);
        }
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_file_writer: Io.File.Writer = .init(.stderr(), io, &stderr_buffer);
    const stderr_writer = &stderr_file_writer.interface;

    try stdout_writer.print("Execution started.\n", .{});
    try stdout_writer.flush();

    const arena = init.arena.allocator();

    const data = tga_loader.loadTga(arena, io, "img/female.tga", stdout_writer, stderr_writer) catch |err| {
        try stderr_writer.print("Error loading TGA file\n", .{});
        try stderr_writer.flush();
        try stdout_writer.flush();
        return err;
    };
    try stdout_writer.flush();

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        const err_str = c.SDL_GetError();
        try stderr_writer.print("SDL_Init Error: {s}\n", .{err_str});
        try stderr_writer.print("Error while initializing SDL\n", .{});
        try stderr_writer.flush();
        try stdout_writer.flush();
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("Simple renderer", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, graphics.SCREEN_WIDTH, graphics.SCREEN_HEIGHT, c.SDL_WINDOW_SHOWN) orelse {
        const err_str = c.SDL_GetError();
        try stderr_writer.print("SDL_CreateWindow Error: {s}\n", .{err_str});
        try stderr_writer.print("Error while initializing SDL\n", .{});
        try stderr_writer.flush();
        try stdout_writer.flush();
        return error.SDLCreateWindowFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const surface = c.SDL_GetWindowSurface(window) orelse {
        const err_str = c.SDL_GetError();
        try stderr_writer.print("SDL_GetWindowSurface Error: {s}\n", .{err_str});
        try stderr_writer.print("Error while initializing SDL\n", .{});
        try stderr_writer.flush();
        try stdout_writer.flush();
        return error.SDLGetWindowSurfaceFailed;
    };

    var quit = false;
    var e: c.SDL_Event = undefined;
    while (!quit) {
        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT) {
                quit = true;
            }

            if (e.type == c.SDL_KEYDOWN) {
                if (e.key.keysym.sym == c.SDLK_q) {
                    quit = true;
                }
            }
        }
        graphics.clearSreen(surface);

        const start = c.SDL_GetTicks();

        loadData(surface, data);

        const end = c.SDL_GetTicks();
        _ = c.SDL_UpdateWindowSurface(window);
        const elapsed = end - start;
        if (elapsed < 16) {
            c.SDL_Delay(16 - elapsed);
        }
    }

    try stdout_writer.print("Execution ended.\n", .{});
    try stdout_writer.flush();
}

// Workaround for MinGW SDL2 linker issues where fseeko64 and ftello64 are expected as dllimports
pub extern fn _ftelli64(stream: ?*anyopaque) callconv(.c) i64;
pub extern fn _fseeki64(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int;

fn ftello64(stream: ?*anyopaque) callconv(.c) i64 {
    return _ftelli64(stream);
}
fn fseeko64(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int {
    return _fseeki64(stream, offset, whence);
}

export const __imp_ftello64: *const fn (?*anyopaque) callconv(.c) i64 = &ftello64;
export const __imp_fseeko64: *const fn (?*anyopaque, i64, c_int) callconv(.c) c_int = &fseeko64;
