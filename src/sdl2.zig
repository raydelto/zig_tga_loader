const std = @import("std");

pub const SDL_Window = opaque {};
pub const SDL_Surface = extern struct {
    flags: u32,
    format: *anyopaque,
    w: i32,
    h: i32,
    pitch: i32,
    pixels: ?*anyopaque,
    userdata: ?*anyopaque,
    locked: i32,
    list_blitmap: ?*anyopaque,
    clip_rect: extern struct { x: i32, y: i32, w: i32, h: i32 },
    map: ?*anyopaque,
    refcount: i32,
};

pub const SDL_Keysym = extern struct {
    scancode: u32,
    sym: i32,
    mod: u16,
    unused: u32,
};

pub const SDL_KeyboardEvent = extern struct {
    type: u32,
    timestamp: u32,
    windowID: u32,
    state: u8,
    repeat: u8,
    padding2: u8,
    padding3: u8,
    keysym: SDL_Keysym,
};

pub const SDL_Event = extern union {
    type: u32,
    key: SDL_KeyboardEvent,
    padding: [56]u8,
};

pub const SDL_INIT_VIDEO: u32 = 0x00000020;
pub const SDL_WINDOW_SHOWN: u32 = 0x00000004;
pub const SDL_WINDOWPOS_UNDEFINED: i32 = @bitCast(@as(u32, 0x1FFF0000));
pub const SDL_QUIT: u32 = 0x100;
pub const SDL_KEYDOWN: u32 = 0x300;
pub const SDLK_q: i32 = 'q';

pub extern fn SDL_Init(flags: u32) c_int;
pub extern fn SDL_Quit() void;
pub extern fn SDL_CreateWindow(title: [*c]const u8, x: c_int, y: c_int, w: c_int, h: c_int, flags: u32) ?*SDL_Window;
pub extern fn SDL_DestroyWindow(window: ?*SDL_Window) void;
pub extern fn SDL_GetWindowSurface(window: ?*SDL_Window) ?*SDL_Surface;
pub extern fn SDL_UpdateWindowSurface(window: ?*SDL_Window) c_int;
pub extern fn SDL_PollEvent(event: ?*SDL_Event) c_int;
pub extern fn SDL_Delay(ms: u32) void;
pub extern fn SDL_GetTicks() u32;
pub extern fn SDL_GetError() [*c]const u8;
