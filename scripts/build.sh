cmake -G Ninja -B build -S . -D CMAKE_BUILD_TYPE=Release
cmake --build build
export DYLD_LIBRARY_PATH="$(pwd)/build/lib"
