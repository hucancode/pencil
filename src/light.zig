const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const Vector3 = rl.Vector3;
const Color = rl.Color;
const Shader = rl.Shader;
const allocator = std.heap.page_allocator;

// Constants
pub const MAX_LIGHTS = 4;

// Light types
pub const LightType = enum(i32) {
    Directional = 0,
    Point = 1,
};

// Light structure
pub const Light = struct {
    type: LightType,
    enabled: bool,
    position: Vector3,
    target: Vector3,
    color: Color,
    attenuation: f32 = 0.0,

    // Shader locations
    enabledLoc: i32 = 0,
    typeLoc: i32 = 0,
    positionLoc: i32 = 0,
    targetLoc: i32 = 0,
    colorLoc: i32 = 0,
    attenuationLoc: i32 = 0,
};

// Global variable to track the number of lights
var lightsCount: i32 = 0;

// Create a light and get shader locations
pub fn createLight(
    lightType: LightType,
    position: Vector3,
    target: Vector3,
    color: Color,
    shader: *Shader,
) Light {
    if (lightsCount >= MAX_LIGHTS) {
        @panic("Maximum number of lights reached");
    }

    var light = Light{
        .type = lightType,
        .enabled = true,
        .position = position,
        .target = target,
        .color = color,
    };

    const lightIndex = lightsCount;
    lightsCount += 1;
    var location = std.fmt.allocPrint(allocator, "{s}[{d}].{s}", .{ "lights", lightIndex, "enabled" }) catch unreachable;
    light.enabledLoc = rl.GetShaderLocation(
        shader.*,
        location.ptr,
    );
    location = std.fmt.allocPrint(allocator, "{s}[{d}].{s}", .{ "lights", lightIndex, "type" }) catch unreachable;
    light.typeLoc = rl.GetShaderLocation(
        shader.*,
        location.ptr,
    );
    location = std.fmt.allocPrint(allocator, "{s}[{d}].{s}", .{ "lights", lightIndex, "position" }) catch unreachable;
    light.positionLoc = rl.GetShaderLocation(
        shader.*,
        location.ptr,
    );
    location = std.fmt.allocPrint(allocator, "{s}[{d}].{s}", .{ "lights", lightIndex, "target" }) catch unreachable;
    light.targetLoc = rl.GetShaderLocation(
        shader.*,
        location.ptr,
    );
    location = std.fmt.allocPrint(allocator, "{s}[{d}].{s}", .{ "lights", lightIndex, "color" }) catch unreachable;
    light.colorLoc = rl.GetShaderLocation(
        shader.*,
        location.ptr,
    );

    updateLightValues(shader, &light);
    return light;
}

// Send light properties to the shader
pub fn updateLightValues(shader: *Shader, light: *Light) void {
    rl.SetShaderValue(shader.*, light.enabledLoc, &@as(i32, @intFromBool(light.enabled)), rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader.*, light.typeLoc, &light.type, rl.SHADER_UNIFORM_INT);

    const position = [3]f32{
        light.position.x,
        light.position.y,
        light.position.z,
    };
    rl.SetShaderValue(shader.*, light.positionLoc, &position, rl.SHADER_UNIFORM_VEC3);

    const target = [3]f32{
        light.target.x,
        light.target.y,
        light.target.z,
    };
    rl.SetShaderValue(shader.*, light.targetLoc, &target, rl.SHADER_UNIFORM_VEC3);

    const color = [4]f32{
        @as(f32, @floatFromInt(light.color.r)) / 255.0,
        @as(f32, @floatFromInt(light.color.g)) / 255.0,
        @as(f32, @floatFromInt(light.color.b)) / 255.0,
        @as(f32, @floatFromInt(light.color.a)) / 255.0,
    };
    rl.SetShaderValue(shader.*, light.colorLoc, &color, rl.SHADER_UNIFORM_VEC4);
}
