# triton-ascend-env

env for building `triton-ascend` and `AscendNPU-IR`

## pixi env

```bash
pixi i

pixi shell
```

## get cann toolkit

- https://www.hiascend.com/developer/download/community/result?module=cann
  `Ascend-cann-toolkit_8.5.0.alpha002_linux-x86_64.run`
  `Ascend-cann-toolkit_8.5.0.alpha002_linux-x86_64.run`

```bash
chmod +x Ascend-cann-toolkit_8.5.0.alpha002_linux-x86_64.run
./Ascend-cann-toolkit_8.5.0.alpha002_linux-x86_64.run --extract=ascend-cann-toolkit
pushd ascend-cann-toolkit/run_package
./Ascend-BiSheng-toolkit_x86.run --extract=ascend-bisheng-toolkit
popd
# hivmc, bishengir-opt, bishengir-compile, bishengir-hivm-compile
# ln -s $PWD/ascend-cann-toolkit/run_package/ascend-bisheng-toolkit/bishengir/bin/* $PWD/.pixi/envs/default/bin/
# only use `hivmc`
ln -s $PWD/ascend-cann-toolkit/run_package/ascend-bisheng-toolkit/bishengir/bin/hivmc $PWD/.pixi/envs/default/bin/hivmc
```

## build `AscendNPU-IR`

TODO

## build `triton-ascend`

TODO
