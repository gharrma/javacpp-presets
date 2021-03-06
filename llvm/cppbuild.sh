#!/bin/bash
# This file is meant to be included by the parent cppbuild.sh script
if [[ -z "$PLATFORM" ]]; then
    pushd ..
    bash cppbuild.sh "$@" llvm
    popd
    exit
fi

case $PLATFORM in
    linux-x86)
        export CC="gcc -m32"
        export CXX="g++ -m32"
        ;;
    linux-x86_64)
        export CC="gcc -m64"
        export CXX="g++ -m64"
        ;;
#    linux-armhf)
#        export CC_FLAGS="clang -target arm -march=armv7 -mfloat-abi=hard"
#        export CXX_FLAGS="-target arm -march=armv7 -mfloat-abi=hard"
#        ;;
    macosx-*)
        ;;
    *)
        echo "Error: Platform \"$PLATFORM\" is not supported"
        return 0
        ;;
esac

LLVM_VERSION=5.0.1
download http://llvm.org/releases/$LLVM_VERSION/llvm-$LLVM_VERSION.src.tar.xz llvm-$LLVM_VERSION.src.tar.xz
download http://llvm.org/releases/$LLVM_VERSION/cfe-$LLVM_VERSION.src.tar.xz cfe-$LLVM_VERSION.src.tar.xz

mkdir -p $PLATFORM
cd $PLATFORM
INSTALL_PATH=`pwd`
echo "Decompressing archives..."
tar --totals -xf ../llvm-$LLVM_VERSION.src.tar.xz
cd llvm-$LLVM_VERSION.src
mkdir -p build tools
cd tools
tar --totals -xf ../../../cfe-$LLVM_VERSION.src.tar.xz
rm -Rf clang
mv cfe-$LLVM_VERSION.src clang
cd ..

# Inject Go debug info bindings (hack).
pwd
cp ../../../bindings/{IRBindings,DIBuilderBindings}.h include/llvm-c/
cp ../../../bindings/{IRBindings,DIBuilderBindings}.{h,cpp} lib/IR/
perl -i.bak -plne 'print "  DIBuilderBindings.cpp\n  IRBindings.cpp" if(/Core.cpp/);' lib/IR/CMakeLists.txt

cd build
$CMAKE -DCMAKE_INSTALL_PREFIX=../.. -DDLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=host -DLIBXML2_LIBRARIES= ..
make -j $MAKEJ
make install > /dev/null

cd ../..
