const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "pencil",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    // Link with Raylib
    exe.linkSystemLibrary("raylib");

    // Add platform-specific libraries (if needed)
    if (builtin.target.os.tag == .linux) {
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("pthread");
    } else if (builtin.target.os.tag == .windows) {
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("kernel32");
    }

    const install = b.getInstallStep();
    const install_data = b.addInstallDirectory(.{
        .source_dir = b.path("src/resources"),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "resources",
    });
    install.dependOn(&install_data.step);

    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
