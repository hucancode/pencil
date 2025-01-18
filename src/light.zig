const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const Vector3 = raylib.Vector3;
const Color = raylib.Color;
const Shader = raylib.Shader;

// Constants
pub const MAX_LIGHTS = 4;

// Light types
pub const LightType = enum {
    Directional,
    Point,
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
    var location = std.fmt.allocPrint(std.heap.page_allocator, "{s}[{d}]", .{"lights", lightIndex}) catch unreachable;
    light.enabledLoc = raylib.GetShaderLocation(
        shader.*, location.ptr,
    );
    location = std.fmt.allocPrint(std.heap.page_allocator, "{s}[{d}].type", .{"lights", lightIndex}) catch unreachable;
    light.typeLoc = raylib.GetShaderLocation(
        shader.*, location.ptr,
    );
    location = std.fmt.allocPrint(std.heap.page_allocator, "{s}[{d}].position", .{"lights", lightIndex}) catch unreachable;
    light.positionLoc = raylib.GetShaderLocation(
        shader.*, location.ptr,
    );
    location = std.fmt.allocPrint(std.heap.page_allocator, "{s}[{d}].target", .{"lights", lightIndex}) catch unreachable;
    light.targetLoc = raylib.GetShaderLocation(
        shader.*, location.ptr,
    );
    location = std.fmt.allocPrint(std.heap.page_allocator, "{s}[{d}].color", .{"lights", lightIndex}) catch unreachable;
    light.colorLoc = raylib.GetShaderLocation(
        shader.*, location.ptr,
    );

    updateLightValues(shader, &light);
    return light;
}

// Send light properties to the shader
pub fn updateLightValues(shader: *Shader, light: *Light) void {
    raylib.SetShaderValue(shader.*, light.enabledLoc, &light.enabled, raylib.SHADER_UNIFORM_INT);
    raylib.SetShaderValue(shader.*, light.typeLoc, &light.type, raylib.SHADER_UNIFORM_INT);

    const position = [3]f32{
        light.position.x,
        light.position.y,
        light.position.z,
    };
    raylib.SetShaderValue(shader.*, light.positionLoc, &position, raylib.SHADER_UNIFORM_VEC3);

    const target = [3]f32{
        light.target.x,
        light.target.y,
        light.target.z,
    };
    raylib.SetShaderValue(shader.*, light.targetLoc, &target, raylib.SHADER_UNIFORM_VEC3);

    const color = [4]f32{
        @as(f32, @floatFromInt(light.color.r)) / 255.0,
        @as(f32, @floatFromInt(light.color.g)) / 255.0,
        @as(f32, @floatFromInt(light.color.b)) / 255.0,
        @as(f32, @floatFromInt(light.color.a)) / 255.0,
    };
    raylib.SetShaderValue(shader.*, light.colorLoc, &color, raylib.SHADER_UNIFORM_VEC4);
}
