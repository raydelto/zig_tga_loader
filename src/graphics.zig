const std = @import("std");
const c = @import("sdl2.zig");

pub const SCREEN_WIDTH: i32 = 252;
pub const SCREEN_HEIGHT: i32 = 195;
pub const TOTAL_PIXELS: usize = @intCast(SCREEN_WIDTH * SCREEN_HEIGHT);
pub const BOX_X_SIZE: i32 = 32;
pub const BOX_Y_SIZE: i32 = 32;

pub fn drawPixel(surface: *c.SDL_Surface, x: i32, y: i32, color: u32) void {
    if (x < 0 or y < 0) return;
    const offset = @as(usize, @intCast(SCREEN_WIDTH * y + x));
    if (offset >= TOTAL_PIXELS) {
        return;
    }

    if (surface.pixels) |pixels_ptr| {
        const pixels: [*]u32 = @ptrCast(@alignCast(pixels_ptr));
        pixels[offset] = color;
    }
}

pub fn clearSreen(surface: *c.SDL_Surface) void {
    if (surface.pixels) |pixels_ptr| {
        const pixels: [*]u32 = @ptrCast(@alignCast(pixels_ptr));
        @memset(pixels[0..TOTAL_PIXELS], 0);
    }
}
