# triton-ascend-env

env for building `triton-ascend` and `AscendNPU-IR`

check [`master`](https://github.com/triton-xyz/triton-ascend-env/tree/master) branch for https://gitcode.com/Ascend/triton-ascend/tree/master

## pixi env

- install pixi

```bash
# https://pixi.prefix.dev/latest/
curl -fsSL https://pixi.sh/install.sh | sh
# or download from
https://github.com/prefix-dev/pixi/releases

chmod +x pixi
mkdir -p ~/.local/bin/ && cp pixi ~/.local/bin/
cat >>~/.bashrc <<EOF
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pixi/bin:$PATH"
# eval "$(pixi shell-hook)"
if command -v pixi &>/dev/null; then
  eval "$(pixi shell-hook 2>/dev/null)"
fi
EOF

# optional: config for china mirrors
mkdir -p ~/.config/pip
cat >~/.config/pip/pip.conf <<EOF
[global]
index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
EOF

mkdir -p ~/.config/uv
cat >~/.config/uv/uv.toml <<EOF
[[index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple/"
default = true
EOF

mkdir -p ~/.pixi
cat >~/.pixi/config.toml <<EOF
# https://pixi.sh/dev/reference/pixi_configuration/
default-channels = ["conda-forge"]

[mirrors]
"https://conda.anaconda.org/conda-forge" = [
  "https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge",
  "https://prefix.dev/conda-forge",
]
"https://conda.anaconda.org/conda-forge/label" = [
  "https://conda.anaconda.org/conda-forge/label",
]
"https://pypi.org/simple" = [
  "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple",
]

# [pypi-config]
# # index-url = "https://pypi.org/simple"
# index-url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
EOF
```

- activate pixi

```bash
pixi i

pixi shell
```

## get cann toolkit

version may change, prefer latest version

- https://www.hiascend.com/developer/download/community/result?module=cann
  `Ascend-cann-toolkit_8.5.0_linux-x86_64.run`
  `Ascend-cann-toolkit_8.5.0_linux-x86_64.run`

```bash
chmod +x Ascend-cann-toolkit_8.5.0_linux-x86_64.run
./Ascend-cann-toolkit_8.5.0_linux-x86_64.run --extract=ascend-cann-toolkit
pushd ascend-cann-toolkit/run_package
./ascendnpu-ir_1.0.0_linux-x86.run --noexec --extract=ascendnpu-ir
./cann-bisheng-compiler_8.5.0_linux-x86_64.run --noexec --extract=cann-bisheng-compiler
# ./cann-asc-devkit_8.5.0_linux-x86_64.run --noexec --extract=cann-asc-devkit
# ./cann-asc-tools_8.5.0_linux-x86_64.run --noexec --extract=cann-asc-tools
popd

# `bishengir-compile`, `bishengir-opt`, `hivmc`
# $PWD/ascend-cann-toolkit/run_package/ascendnpu-ir/bishengir/bin
# `bisheng` and `llvm-*`
# $PWD/ascend-cann-toolkit/run_package/cann-bisheng-compiler/bisheng_compiler/bin

# prefer `activation.env` in `pixi.toml` instead of `ln -s`
# ln -s bin/* $PWD/.pixi/envs/default/bin/
```

## build `AscendNPU-IR`

```bash
# tested on `ce2db36d0c9a5b8f59aa9a791ec9c74454b7836b`
# git clone git@github.com:Ascend/AscendNPU-IR.git
git clone https://gitcode.com/Ascend/AscendNPU-IR.git
ln -s $PWD/AscendNPU-IR-extra/* $PWD/AscendNPU-IR/

pushd AscendNPU-IR

# NOTE: It may fail and needs to be handled manually
git apply patch.patch

# git submodule update --init --depth 1
bash llvm_download.sh
pushd third-party
bash ../build-tools/apply_patches.sh
popd
ln -s $PWD/CMakePresets.json $PWD/third-party/llvm-project/llvm/CMakePresets.json

rm -rf build/CMakeFiles
rm -rf build/CMakeCache.txt
cmake --preset osx -S$PWD/third-party/llvm-project/llvm -B$PWD/build
cmake --build $PWD/build --target all

popd
```

## build `triton-ascend`

```bash
# check `triton-ascend/llvm-hash.txt` for llvm commit
# tested on llvm-project `b5cc222d7429fe6f18c787f633d5262fac2e676f`
git clone git@github.com:gglin001/llvm-ascend.git
pushd llvm-ascend
bash scripts/llvm_download.sh
bash scripts/llvm_build.sh
popd
```

```bash
# tested on `main` branch `91bede2c9efa364fd7691ddd02c8fefd4f9887b7`
# git clone git@github.com:Ascend/triton-ascend.git
git clone https://gitcode.com/Ascend/triton-ascend.git
ln -s $PWD/triton-ascend-extra/* $PWD/triton-ascend/
ln -s $PWD/llvm-ascend $PWD/triton-ascend/llvm-ascend

pushd triton-ascend

# NOTE: It may fail and needs to be handled manually
git apply patch.patch

git submodule update --init --depth 1

rm -rf build/CMakeFiles
rm -rf build/CMakeCache.txt
[[ "$(uname)" == "Darwin" ]] && PRESET="osx_lld" || PRESET="osx"
cmake --preset $PRESET -S$PWD -B$PWD/build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DPython3_EXECUTABLE=$(which python)
cmake --build $PWD/build --target all

mkdir -p $PWD/python/triton/_C
rm -f $PWD/python/triton/_C/libtriton.so &&
  ln -s $PWD/build/libtriton.so $PWD/python/triton/_C/libtriton.so
rm -f $PWD/third_party/ascend/backend/triton-adapter-opt &&
  ln -s $PWD/build/bin/triton-adapter-opt $PWD/third_party/ascend/backend/triton-adapter-opt

pushd python
# disable
# ext_modules=[CMakeExtension("triton", "triton/_C/")],
TRITON_OFFLINE_BUILD=1 DEBUG=1 uv pip install --system -e . --no-build-isolation -v
popd
# uv pip uninstall --system triton-ascend

python -c "import triton.language as tl"
python -c "from triton import jit"

popd
```

## work with `torch_npu`

TODO

## work with `flaggems`

TODO: how to install torch-npu from src

```bash
git clone git@github.com:flagos-ai/FlagGems.git
# git clone https://gitcode.com/gh_mirrors/fl/FlagGems.git

pushd FlagGems
uv pip install --system --no-build-isolation -e . -v

export GEMS_VENDOR="ascend"
python -c "import flag_gems"

popd
```

## work with `cann` docker image

https://www.hiascend.com/developer/ascendhub/detail/17da20d1c2b6493cb38765adeba85884

```bash

docker pull --platform=amd64 swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.5.0-910b-ubuntu22.04-py3.11
docker tag swr.cn-south-1.myhuaweicloud.com/ascendhub/cann:8.5.0-910b-ubuntu22.04-py3.11 \
  cann:8.5.0-910b-ubuntu22.04-py3.11

args=(
  --name cann_dev_1
  --entrypoint /usr/bin/bash
  cann:8.5.0-910b-ubuntu22.04-py3.11
)
docker run -d -it "${args[@]}"
docker exec -it cann_dev_1 bash
```
