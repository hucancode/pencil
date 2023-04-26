run: build
	cd game && ../build/game/pencil
.PHONY: build
build:
	cd build && make
format:
	clang-format -style=file -i game/*.{c,h}
