const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "pencil",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });
    const raylib = b.dependency("raylib", .{
        .target = b.host,
        .optimize = b.standardOptimizeOption(.{}),
        .net = true,
    });
    exe.linkLibrary(raylib.artifact("raylib"));

    if (builtin.target.os.tag == .linux or builtin.target.os.tag == .macos) {
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("pthread");
    } else if (builtin.target.os.tag == .windows) {
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("kernel32");
    }

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
