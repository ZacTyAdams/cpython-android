# You run this on a local mac machine
# some pre-reqs:
# xcode-select --install
# brew update
# brew install openssl@3 readline xz zlib bzip2 pkg-config

# Build the macos binary from the root of the repo
cd .. && make clean || true && git clean -fdx -e Doc/venv
mkdir -p build-macos
cd build-macos

export OPENSSL_DIR="$(brew --prefix openssl@3)"
export READLINE_DIR="$(brew --prefix readline)"
export XZ_DIR="$(brew --prefix xz)"
export ZLIB_DIR="$(brew --prefix zlib)"
export BZIP2_DIR="$(brew --prefix bzip2)"

export CPPFLAGS="-I$OPENSSL_DIR/include -I$READLINE_DIR/include -I$XZ_DIR/include -I$ZLIB_DIR/include -I$BZIP2_DIR/include"
export LDFLAGS="-L$OPENSSL_DIR/lib -L$READLINE_DIR/lib -L$XZ_DIR/lib -L$ZLIB_DIR/lib -L$BZIP2_DIR/lib"
export PKG_CONFIG_PATH="$OPENSSL_DIR/lib/pkgconfig:$READLINE_DIR/lib/pkgconfig:$XZ_DIR/lib/pkgconfig:$ZLIB_DIR/lib/pkgconfig:$BZIP2_DIR/lib/pkgconfig"

export PREFIX="$PWD/../out/prefix"

../configure \
  --prefix="$PREFIX" \
  --with-openssl="$OPENSSL_DIR" \
  --with-readline=readline \
  --with-ensurepip=install \
  --enable-optimizations

# test and make it
make -j"$(sysctl -n hw.ncpu)"
make install

cd .. && rm -rf stage && mkdir -p stage && cp -a out/prefix stage/




# build the tarball
cd stage

# a little cleanup
PREFIX="$(pwd)/prefix"

# Strip main executables + dylibs + extension modules
find "$PREFIX" -type f \( -perm -111 -o -name "*.dylib" -o -name "*.so" \) -print0 \
  | xargs -0 -n1 strip -x 2>/dev/null || true

# remove tests, caches and compiled files 
PYVER="3.15"
rm -rf "$PREFIX/lib/python$PYVER/test"
rm -rf "$PREFIX/lib/python$PYVER/idlelib/idle_test"
rm -rf "$PREFIX/lib/python$PYVER/unittest/test"
rm -rf "$PREFIX/lib/python$PYVER/**/__pycache__" 2>/dev/null || true
find "$PREFIX" -name "*.pyc" -delete
find "$PREFIX" -name "*.pyo" -delete
find "$PREFIX" -name "*.a" -delete



tar -czf darwin-arm64.tar.gz prefix
