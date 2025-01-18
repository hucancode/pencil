const std = @import("std");
const builtin = @import("builtin");
const rl = @cImport({
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
const allocator = std.heap.page_allocator;

var camera: rl.Camera3D = undefined;
var lights: [MAX_LIGHTS]light.Light = undefined;
var model: rl.Model = undefined;
var cube: rl.Model = undefined;
var lightShader: rl.Shader = undefined;
var normalShader: rl.Shader = undefined;
var sketchShader: rl.Shader = undefined;
var normalRenderTarget: rl.RenderTexture2D = undefined;
var lightingRenderTarget: rl.RenderTexture2D = undefined;

fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}

const VEC3_ZERO = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };

fn setupWorld() void {
    camera.position = vec3(2.0, 4.0, 6.0);
    camera.target = vec3(0.0, 0.5, 0.0);
    camera.up = vec3(0.0, 1.0, 0.0);
    camera.fovy = 45.0;
    camera.projection = rl.CAMERA_PERSPECTIVE;

    model = rl.LoadModelFromMesh(rl.GenMeshPlane(10.0, 10.0, 3, 3));
    cube = rl.LoadModelFromMesh(rl.GenMeshCube(2.0, 4.0, 2.0));
}

fn setupLightPass() void {
    lightingRenderTarget = rl.LoadRenderTexture(screenWidth, screenHeight);
    const vsPath = std.fmt.allocPrint(allocator, "resources/shaders/glsl{d}/lighting.vs", .{GLSL_VERSION}) catch unreachable;
    const fsPath = std.fmt.allocPrint(allocator, "resources/shaders/glsl{d}/lighting.fs", .{GLSL_VERSION}) catch unreachable;
    lightShader = rl.LoadShader(vsPath.ptr, fsPath.ptr);

    lightShader.locs[rl.SHADER_LOC_VECTOR_VIEW] = rl.GetShaderLocation(lightShader, "viewPos");

    const ambient: [4]f32 = .{ 0.1, 0.1, 0.1, 1.0 };
    rl.SetShaderValue(lightShader, rl.GetShaderLocation(lightShader, "ambient"), &ambient, rl.SHADER_UNIFORM_VEC4);

    lights[0] = light.createLight(light.LightType.Point, vec3(-2, 1, -2), VEC3_ZERO, rl.YELLOW, &lightShader);
    lights[1] = light.createLight(light.LightType.Point, vec3(2, 1, 2), VEC3_ZERO, rl.RED, &lightShader);
    lights[2] = light.createLight(light.LightType.Point, vec3(-2, 1, 2), VEC3_ZERO, rl.GREEN, &lightShader);
    lights[3] = light.createLight(light.LightType.Point, vec3(2, 1, -2), VEC3_ZERO, rl.BLUE, &lightShader);
}

fn setupNormalPass() void {
    normalRenderTarget = rl.LoadRenderTexture(screenWidth, screenHeight);
    const vsPath = std.fmt.allocPrint(allocator, "resources/shaders/glsl{d}/normal.vs", .{GLSL_VERSION}) catch unreachable;
    const fsPath = std.fmt.allocPrint(allocator, "resources/shaders/glsl{d}/normal.fs", .{GLSL_VERSION}) catch unreachable;
    normalShader = rl.LoadShader(
        vsPath.ptr,
        fsPath.ptr,
    );
    normalShader.locs[rl.SHADER_LOC_VECTOR_VIEW] = rl.GetShaderLocation(normalShader, "viewPos");
}

fn setupSketchPass() void {
    const fsPath = std.fmt.allocPrint(allocator, "resources/shaders/glsl{d}/sketch.fs", .{GLSL_VERSION}) catch unreachable;
    sketchShader = rl.LoadShader(
        null,
        fsPath.ptr,
    );
    sketchShader.locs[rl.SHADER_LOC_MAP_DIFFUSE] = rl.GetShaderLocation(sketchShader, "lighting");
    sketchShader.locs[rl.SHADER_LOC_MAP_NORMAL] = rl.GetShaderLocation(sketchShader, "normal");
    const resolution: [2]f32 = .{ screenWidth, screenHeight };
    rl.SetShaderValue(sketchShader, rl.GetShaderLocation(sketchShader, "resolution"), &resolution, rl.SHADER_UNIFORM_VEC2);
}

fn drawScene() void {
    rl.ClearBackground(rl.RAYWHITE);
    rl.BeginMode3D(camera);
    rl.DrawModel(model, VEC3_ZERO, 1.0, rl.WHITE);
    rl.DrawModel(cube, VEC3_ZERO, 1.0, rl.WHITE);

    for (lights) |l| {
        if (l.enabled) {
            rl.DrawSphereEx(l.position, 0.2, 8, 8, l.color);
        } else {
            rl.DrawSphereWires(l.position, 0.2, 8, 8, rl.ColorAlpha(l.color, 0.3));
        }
    }

    rl.DrawGrid(10, 1.0);
    rl.EndMode3D();
}

fn drawNormal() void {
    rl.SetShaderValue(normalShader, normalShader.locs[rl.SHADER_LOC_VECTOR_VIEW], &camera.position, rl.SHADER_UNIFORM_VEC3);
    model.materials[0].shader = normalShader;
    cube.materials[0].shader = normalShader;
    drawScene();
}

fn drawMainLight() void {
    rl.SetShaderValue(lightShader, lightShader.locs[rl.SHADER_LOC_VECTOR_VIEW], &camera.position, rl.SHADER_UNIFORM_VEC3);
    for (&lights) |*l| {
        light.updateLightValues(&lightShader, l);
    }
    model.materials[0].shader = lightShader;
    cube.materials[0].shader = lightShader;
    drawScene();
}

fn drawSketch() void {
    rl.ClearBackground(rl.RAYWHITE);
    rl.BeginShaderMode(sketchShader);
    rl.SetShaderValueTexture(sketchShader, sketchShader.locs[rl.SHADER_LOC_MAP_NORMAL], normalRenderTarget.texture);
    const r = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(lightingRenderTarget.texture.width),
        .height = -@as(f32, @floatFromInt(lightingRenderTarget.texture.height)),
    };
    const p = rl.Vector2{ .x = 0, .y = 0 };
    rl.DrawTextureRec(lightingRenderTarget.texture, r, p, rl.WHITE);
    rl.EndShaderMode();
}

fn setup() void {
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(screenWidth, screenHeight, "Zig + rl - Sketch Shader");
    rl.SetTargetFPS(60);

    setupWorld();
    setupLightPass();
    setupNormalPass();
    setupSketchPass();
}

fn update() void {
    rl.UpdateCamera(&camera, rl.CAMERA_ORBITAL);

    if (rl.IsKeyPressed(rl.KEY_Y)) lights[0].enabled = !lights[0].enabled;
    if (rl.IsKeyPressed(rl.KEY_R)) lights[1].enabled = !lights[1].enabled;
    if (rl.IsKeyPressed(rl.KEY_G)) lights[2].enabled = !lights[2].enabled;
    if (rl.IsKeyPressed(rl.KEY_B)) lights[3].enabled = !lights[3].enabled;
}

fn draw() void {
    rl.BeginTextureMode(normalRenderTarget);
    drawNormal();
    rl.EndTextureMode();
    rl.BeginTextureMode(lightingRenderTarget);
    drawMainLight();
    rl.EndTextureMode();
    rl.BeginDrawing();
    rl.ClearBackground(rl.RAYWHITE);
    drawSketch();
    rl.DrawFPS(10, 10);
    rl.DrawText("Use keys [Y][R][G][B] to toggle lights", 10, 40, 20, rl.DARKGRAY);
    rl.EndDrawing();
}

fn dispose() void {
    rl.UnloadModel(model);
    rl.UnloadModel(cube);
    rl.UnloadShader(lightShader);
    rl.UnloadShader(normalShader);
    rl.UnloadShader(sketchShader);
    rl.CloseWindow();
}

pub fn main() !void {
    setup();
    while (!rl.WindowShouldClose()) {
        update();
        draw();
    }
    dispose();
}
