export CC="cc"
export CC_FLAGS="-fwrapv -fsanitize=address -fsanitize=undefined"
export CC_LINK_FLAGS="-L lib -lwebview"
export DYLD_LIBRARY_PATH="$(pwd)/lib"
