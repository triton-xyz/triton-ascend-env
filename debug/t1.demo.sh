PPWD=$(pwd)
DIR=$PPWD/debug/dump
mkdir -p $DIR

export MLIR_ENABLE_DUMP="1"
export TRITON_DUMP_DIR=$DIR

export TRITON_HOME=$PPWD/debug
export TRITON_ALWAYS_COMPILE="1"

# export MLIR_ROOT="$PPWD/AscendNPU-IR/build"
# export LLVM_ROOT="$PPWD/AscendNPU-IR/build"
export MLIR_ROOT="$PPWD/llvm-ascend/llvm-project/build"
export LLVM_ROOT="$PPWD/llvm-ascend/llvm-project/build"

# export PATH="$PPWD/AscendNPU-IR/build/bin:${PATH}"
echo "bishengir-compile: $(which bishengir-compile)"

pushd debug

python test_vec_add.py 2>&1 | tee $DIR/compile.log

popd
