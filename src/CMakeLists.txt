project(pencil)
add_executable(${PROJECT_NAME} main.c rlights.c)

target_link_libraries(${PROJECT_NAME} raylib)

file(GLOB resources resources/*)
file(COPY ${resources} DESTINATION "resources/")
