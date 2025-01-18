const std = @import("std");
const builtin = @import("builtin");
const raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const light = @import("light.zig");
const GLSL_VERSION = blk: {
    if (builtin.os.tag == .linux or builtin.os.tag == .windows or builtin.os.tag == .macos) {
        break :blk 330; // Desktop platforms
    } else {
        break :blk 100; // Raspberry Pi, Android, Web
    }
};
const MAX_LIGHTS = 4;
const screenWidth = 1024;
const screenHeight = 768;

var camera: raylib.Camera3D = undefined;
var lights: [MAX_LIGHTS]light.Light = undefined;
var model: raylib.Model = undefined;
var cube: raylib.Model = undefined;
var lightShader: raylib.Shader = undefined;
var normalShader: raylib.Shader = undefined;
var sketchShader: raylib.Shader = undefined;
var normalRenderTarget: raylib.RenderTexture2D = undefined;
var lightingRenderTarget: raylib.RenderTexture2D = undefined;

fn vec3(x: f32, y: f32, z: f32) raylib.Vector3 {
    return raylib.Vector3{ .x = x, .y = y, .z = z };
}

const VEC3_ZERO = raylib.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };

fn setupWorld() void {
    camera.position = vec3(2.0, 4.0, 6.0);
    camera.target = vec3(0.0, 0.5, 0.0);
    camera.up = vec3(0.0, 1.0, 0.0);
    camera.fovy = 45.0;
    camera.projection = raylib.CAMERA_PERSPECTIVE;

    model = raylib.LoadModelFromMesh(raylib.GenMeshPlane(10.0, 10.0, 3, 3));
    cube = raylib.LoadModelFromMesh(raylib.GenMeshCube(2.0, 4.0, 2.0));
}

fn setupLightPass() void {
    lightingRenderTarget = raylib.LoadRenderTexture(screenWidth, screenHeight);
    const vsPath = std.fmt.allocPrint(std.heap.page_allocator, "resources/shaders/glsl{d}/lighting.vs", .{GLSL_VERSION}) catch unreachable;
    const fsPath = std.fmt.allocPrint(std.heap.page_allocator, "resources/shaders/glsl{d}/lighting.fs", .{GLSL_VERSION}) catch unreachable;
    lightShader = raylib.LoadShader(vsPath.ptr, fsPath.ptr);

    lightShader.locs[raylib.SHADER_LOC_VECTOR_VIEW] = raylib.GetShaderLocation(lightShader, "viewPos");

    const ambient: [4]f32 = .{ 0.1, 0.1, 0.1, 1.0 };
    raylib.SetShaderValue(lightShader, raylib.GetShaderLocation(lightShader, "ambient"), &ambient, raylib.SHADER_UNIFORM_VEC4);

    lights[0] = light.createLight(light.LightType.Point, vec3(-2, 1, -2), VEC3_ZERO, raylib.YELLOW, &lightShader);
    lights[1] = light.createLight(light.LightType.Point, vec3(2, 1, 2), VEC3_ZERO, raylib.RED, &lightShader);
    lights[2] = light.createLight(light.LightType.Point, vec3(-2, 1, 2), VEC3_ZERO, raylib.GREEN, &lightShader);
    lights[3] = light.createLight(light.LightType.Point, vec3(2, 1, -2), VEC3_ZERO, raylib.BLUE, &lightShader);
}

fn setupNormalPass() void {
    normalRenderTarget = raylib.LoadRenderTexture(screenWidth, screenHeight);
    const vsPath = std.fmt.allocPrint(std.heap.page_allocator, "resources/shaders/glsl{d}/normal.vs", .{GLSL_VERSION}) catch unreachable;
    const fsPath = std.fmt.allocPrint(std.heap.page_allocator, "resources/shaders/glsl{d}/normal.fs", .{GLSL_VERSION}) catch unreachable;
    normalShader = raylib.LoadShader(
        vsPath.ptr,
        fsPath.ptr,
    );
    normalShader.locs[raylib.SHADER_LOC_VECTOR_VIEW] = raylib.GetShaderLocation(normalShader, "viewPos");
}

fn setupSketchPass() void {
    const fsPath = std.fmt.allocPrint(std.heap.page_allocator, "resources/shaders/glsl{d}/sketch.fs", .{GLSL_VERSION}) catch unreachable;
    sketchShader = raylib.LoadShader(
        null,
        fsPath.ptr,
    );
    sketchShader.locs[raylib.SHADER_LOC_MAP_DIFFUSE] = raylib.GetShaderLocation(sketchShader, "lighting");
    sketchShader.locs[raylib.SHADER_LOC_MAP_NORMAL] = raylib.GetShaderLocation(sketchShader, "normal");
    const resolution: [2]f32 = .{ screenWidth, screenHeight };
    raylib.SetShaderValue(sketchShader, raylib.GetShaderLocation(sketchShader, "resolution"), &resolution, raylib.SHADER_UNIFORM_VEC2);
}

fn drawScene() void {
    raylib.ClearBackground(raylib.RAYWHITE);
    raylib.BeginMode3D(camera);
    raylib.DrawModel(model, VEC3_ZERO, 1.0, raylib.WHITE);
    raylib.DrawModel(cube, VEC3_ZERO, 1.0, raylib.WHITE);

    for (lights) |l| {
        if (l.enabled) {
            raylib.DrawSphereEx(l.position, 0.2, 8, 8, l.color);
        } else {
            raylib.DrawSphereWires(l.position, 0.2, 8, 8, raylib.ColorAlpha(l.color, 0.3));
        }
    }

    raylib.DrawGrid(10, 1.0);
    raylib.EndMode3D();
}

fn drawNormal() void {
    raylib.SetShaderValue(normalShader, normalShader.locs[raylib.SHADER_LOC_VECTOR_VIEW], &camera.position, raylib.SHADER_UNIFORM_VEC3);
    model.materials[0].shader = normalShader;
    cube.materials[0].shader = normalShader;
    drawScene();
}

fn drawMainLight() void {
    raylib.SetShaderValue(lightShader, lightShader.locs[raylib.SHADER_LOC_VECTOR_VIEW], &camera.position, raylib.SHADER_UNIFORM_VEC3);
    for (&lights) |*l| {
        light.updateLightValues(&lightShader, l);
    }
    model.materials[0].shader = lightShader;
    cube.materials[0].shader = lightShader;
    drawScene();
}

fn drawSketch() void {
    raylib.ClearBackground(raylib.RAYWHITE);
    raylib.BeginShaderMode(sketchShader);
    raylib.SetShaderValueTexture(sketchShader, sketchShader.locs[raylib.SHADER_LOC_MAP_NORMAL], normalRenderTarget.texture);
    const r = raylib.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(lightingRenderTarget.texture.width),
        .height = -@as(f32, @floatFromInt(lightingRenderTarget.texture.height)),
    };
    const p = raylib.Vector2{ .x = 0, .y = 0 };
    raylib.DrawTextureRec(lightingRenderTarget.texture, r, p, raylib.WHITE);
    raylib.EndShaderMode();
}

fn setup() void {
    raylib.SetConfigFlags(raylib.FLAG_MSAA_4X_HINT);
    raylib.InitWindow(screenWidth, screenHeight, "Zig + Raylib - Sketch Shader");
    raylib.SetTargetFPS(60);

    setupWorld();
    setupLightPass();
    setupNormalPass();
    setupSketchPass();
}

fn update() void {
    raylib.UpdateCamera(&camera, raylib.CAMERA_ORBITAL);

    if (raylib.IsKeyPressed(raylib.KEY_Y)) lights[0].enabled = !lights[0].enabled;
    if (raylib.IsKeyPressed(raylib.KEY_R)) lights[1].enabled = !lights[1].enabled;
    if (raylib.IsKeyPressed(raylib.KEY_G)) lights[2].enabled = !lights[2].enabled;
    if (raylib.IsKeyPressed(raylib.KEY_B)) lights[3].enabled = !lights[3].enabled;
}

fn draw() void {
    raylib.BeginTextureMode(normalRenderTarget);
    drawNormal();
    raylib.EndTextureMode();
    raylib.BeginTextureMode(lightingRenderTarget);
    drawMainLight();
    raylib.EndTextureMode();
    raylib.BeginDrawing();
    raylib.ClearBackground(raylib.RAYWHITE);
    drawSketch();
    raylib.DrawFPS(10, 10);
    raylib.DrawText("Use keys [Y][R][G][B] to toggle lights", 10, 40, 20, raylib.DARKGRAY);
    raylib.EndDrawing();
}

fn dispose() void {
    raylib.UnloadModel(model);
    raylib.UnloadModel(cube);
    raylib.UnloadShader(lightShader);
    raylib.UnloadShader(normalShader);
    raylib.UnloadShader(sketchShader);
    raylib.CloseWindow();
}

pub fn main() !void {
    setup();
    while (!raylib.WindowShouldClose()) {
        update();
        draw();
    }
    dispose();
}
