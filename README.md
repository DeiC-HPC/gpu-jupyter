GPU Jupyter
===========
A platform for building Jupyter notebooks with GPU support using [nix](https://nixos.org/) flakes and [jupyenv](https://github.com/tweag/jupyenv).

## Building
To build the container, you can simply just run `nix build`.

## Adding extra kernels
The kernels are based in the kernels folder and the [CUDA](/kernels/cuda/default.nix) and [HIP](/kernels/hip/default.nix) kernels can be used as examples.
When they have been added, they also need to be enabled, which can be done in `flake.nix`.

There are some remnants of old GCC and clang kernels in the packages folder, which can with some work be enabled.

## Nice to haves
List of features that would be nice to have, but we have not developed yet:
- Kernel enablement through inputs
- Python kernel with GPU support