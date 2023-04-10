/*******************************************************************************************
 *
 *   raylib [shaders] example - basic lighting
 *
 *   NOTE: This example requires raylib OpenGL 3.3 or ES2 versions for shaders
 *support, OpenGL 1.1 does not support shaders, recompile raylib to OpenGL 3.3
 *version.
 *
 *   NOTE: Shaders used in this example are #version 330 (OpenGL 3.3).
 *
 *   Example originally created with raylib 3.0, last time updated with
 *raylib 4.2
 *
 *   Example contributed by Chris Camacho (@codifies) and reviewed by Ramon
 *Santamaria (@raysan5)
 *
 *   Example licensed under an unmodified zlib/libpng license, which is an
 *OSI-certified, BSD-like license that allows static linking with closed source
 *software
 *
 *   Copyright (c) 2019-2023 Chris Camacho (@codifies) and Ramon Santamaria
 *(@raysan5)
 *
 ********************************************************************************************/

#include "raylib.h"
#include "raymath.h"
#include "rlights.h"

#if defined(PLATFORM_DESKTOP)
#define GLSL_VERSION 330
#else  // PLATFORM_RPI, PLATFORM_ANDROID, PLATFORM_WEB
#define GLSL_VERSION 100
#endif

const int screenWidth = 800;
const int screenHeight = 450;
Camera camera = {0};
Light lights[MAX_LIGHTS] = {0};
Model model;
Model cube;
Shader lightShader;
Shader normalShader;
Shader sketchShader;
RenderTexture2D normalRenderTarget;
RenderTexture2D lightingRenderTarget;

void setupWorld() {
  camera.position = (Vector3){2.0f, 4.0f, 6.0f};  // Camera position
  camera.target = (Vector3){0.0f, 0.5f, 0.0f};    // Camera looking at point
  camera.up = (Vector3){
      0.0f, 1.0f, 0.0f};  // Camera up vector (rotation towards target)
  camera.fovy = 45.0f;    // Camera field-of-view Y
  camera.projection = CAMERA_PERSPECTIVE;  // Camera projection type
  model = LoadModelFromMesh(GenMeshPlane(10.0f, 10.0f, 3, 3));
  cube = LoadModelFromMesh(GenMeshCube(2.0f, 4.0f, 2.0f));
}

void setupLightPass() {
  lightingRenderTarget = LoadRenderTexture(screenWidth, screenHeight);
  lightShader = LoadShader(
      TextFormat("resources/shaders/glsl%i/lighting.vs", GLSL_VERSION),
      TextFormat("resources/shaders/glsl%i/lighting.fs", GLSL_VERSION));
  lightShader.locs[SHADER_LOC_VECTOR_VIEW] =
      GetShaderLocation(lightShader, "viewPos");
  // NOTE: "matModel" location name is automatically assigned on shader loading,
  // no need to get the location again if using that uniform name
  // shader.locs[SHADER_LOC_MATRIX_MODEL] = GetShaderLocation(shader,
  // "matModel");
  SetShaderValue(lightShader, GetShaderLocation(lightShader, "ambient"),
      (float[4]){0.1f, 0.1f, 0.1f, 1.0f}, SHADER_UNIFORM_VEC4);
  lights[0] = CreateLight(
      LIGHT_POINT, (Vector3){-2, 1, -2}, Vector3Zero(), YELLOW, lightShader);
  lights[1] = CreateLight(
      LIGHT_POINT, (Vector3){2, 1, 2}, Vector3Zero(), RED, lightShader);
  lights[2] = CreateLight(
      LIGHT_POINT, (Vector3){-2, 1, 2}, Vector3Zero(), GREEN, lightShader);
  lights[3] = CreateLight(
      LIGHT_POINT, (Vector3){2, 1, -2}, Vector3Zero(), BLUE, lightShader);
}

void setupNormalPass() {
  normalRenderTarget = LoadRenderTexture(screenWidth, screenHeight);
  normalShader =
      LoadShader(TextFormat("resources/shaders/glsl%i/normal.vs", GLSL_VERSION),
          TextFormat("resources/shaders/glsl%i/normal.fs", GLSL_VERSION));
  normalShader.locs[SHADER_LOC_VECTOR_VIEW] =
      GetShaderLocation(normalShader, "viewPos");
}

void setupSketchPass() {
  sketchShader = LoadShader(
      0, TextFormat("resources/shaders/glsl%i/sketch.fs", GLSL_VERSION));
  sketchShader.locs[SHADER_LOC_MAP_DIFFUSE] =
      GetShaderLocation(sketchShader, "lighting");
  sketchShader.locs[SHADER_LOC_MAP_NORMAL] =
      GetShaderLocation(sketchShader, "normal");
}

void drawNormal() {
  float cameraPos[3] = {
      camera.position.x, camera.position.y, camera.position.z};
  SetShaderValue(normalShader, normalShader.locs[SHADER_LOC_VECTOR_VIEW],
      cameraPos, SHADER_UNIFORM_VEC3);
  model.materials[0].shader = normalShader;
  cube.materials[0].shader = normalShader;
  ClearBackground(RAYWHITE);
  BeginMode3D(camera);
  DrawModel(model, Vector3Zero(), 1.0f, WHITE);
  DrawModel(cube, Vector3Zero(), 1.0f, WHITE);
  for (int i = 0; i < MAX_LIGHTS; i++) {
    if (lights[i].enabled)
      DrawSphereEx(lights[i].position, 0.2f, 8, 8, lights[i].color);
    else
      DrawSphereWires(
          lights[i].position, 0.2f, 8, 8, ColorAlpha(lights[i].color, 0.3f));
  }
  EndMode3D();
}

void drawMainLight() {
  float cameraPos[3] = {
      camera.position.x, camera.position.y, camera.position.z};
  SetShaderValue(lightShader, lightShader.locs[SHADER_LOC_VECTOR_VIEW],
      cameraPos, SHADER_UNIFORM_VEC3);
  for (int i = 0; i < MAX_LIGHTS; i++)
    UpdateLightValues(lightShader, lights[i]);
  model.materials[0].shader = lightShader;
  cube.materials[0].shader = lightShader;
  ClearBackground(RAYWHITE);
  BeginMode3D(camera);
  DrawModel(model, Vector3Zero(), 1.0f, WHITE);
  DrawModel(cube, Vector3Zero(), 1.0f, WHITE);
  for (int i = 0; i < MAX_LIGHTS; i++) {
    if (lights[i].enabled)
      DrawSphereEx(lights[i].position, 0.2f, 8, 8, lights[i].color);
    else
      DrawSphereWires(
          lights[i].position, 0.2f, 8, 8, ColorAlpha(lights[i].color, 0.3f));
  }
  DrawGrid(10, 1.0f);
  EndMode3D();
}

void drawSketch() {
  ClearBackground(RAYWHITE);
  BeginShaderMode(sketchShader);
  SetShaderValueTexture(sketchShader, sketchShader.locs[SHADER_LOC_MAP_NORMAL],
      normalRenderTarget.texture);
  Rectangle r = {0, 0, (float)lightingRenderTarget.texture.width,
      (float)-lightingRenderTarget.texture.height};
  Vector2 p = {0, 0};
  DrawTextureRec(lightingRenderTarget.texture, r, p, WHITE);
  EndShaderMode();
}

void setup() {
  SetConfigFlags(FLAG_MSAA_4X_HINT);
  InitWindow(
      screenWidth, screenHeight, "raylib [shaders] example - basic lighting");
  SetTargetFPS(60);
  setupWorld();
  setupLightPass();
  setupNormalPass();
  setupSketchPass();
}

void draw() {
  BeginTextureMode(normalRenderTarget);
  drawNormal();
  EndTextureMode();
  BeginTextureMode(lightingRenderTarget);
  drawMainLight();
  EndTextureMode();
  BeginDrawing();
  ClearBackground(RAYWHITE);
  drawSketch();
  DrawFPS(10, 10);
  DrawText("Use keys [Y][R][G][B] to toggle lights", 10, 40, 20, DARKGRAY);
  EndDrawing();
}

void update() {
  UpdateCamera(&camera, CAMERA_ORBITAL);
  if (IsKeyPressed(KEY_Y)) {
    lights[0].enabled = !lights[0].enabled;
  }
  if (IsKeyPressed(KEY_R)) {
    lights[1].enabled = !lights[1].enabled;
  }
  if (IsKeyPressed(KEY_G)) {
    lights[2].enabled = !lights[2].enabled;
  }
  if (IsKeyPressed(KEY_B)) {
    lights[3].enabled = !lights[3].enabled;
  }
}

void dispose() {
  UnloadModel(model);
  UnloadModel(cube);
  UnloadShader(lightShader);
  UnloadShader(normalShader);
  UnloadShader(sketchShader);
}

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
int main(void) {
  setup();
  while (!WindowShouldClose()) {
    update();
    draw();
  }
  dispose();
  CloseWindow();
  return 0;
}
