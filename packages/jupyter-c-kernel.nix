{ python3Packages, gccOffload, writeText }:

let
  patch = writeText "jupyter-c-kernel-patch" ''
    diff -Naur a/jupyter_c_kernel/kernel.py b/jupyter_c_kernel/kernel.py
    --- a/jupyter_c_kernel/kernel.py	2020-10-13 13:02:54.074891486 +0200
    +++ b/jupyter_c_kernel/kernel.py	2020-10-13 13:05:34.268882881 +0200
    @@ -113,8 +113,8 @@
                                       lambda contents: self._write_to_stderr(contents.decode()))
     
         def compile_with_gcc(self, source_filename, binary_filename, cflags=None, ldflags=None):
    -        cflags = ['-std=c11', '-fPIC', '-shared', '-rdynamic'] + cflags
    -        args = ['gcc', source_filename] + cflags + ['-o', binary_filename] + ldflags
    +        cflags = ['-std=c++17', '-fPIC', '-shared', '-rdynamic', '-fopenmp', '-fno-stack-protector', '-foffload=-lm', '-foffload=-misa=sm_35'] + cflags
    +        args = ['g++', source_filename] + cflags + ['-o', binary_filename] + ldflags
             return self.create_jupyter_subprocess(args)
     
         def _filter_magics(self, code):
  '';
in
python3Packages.jupyter-c-kernel.overrideAttrs (attrs: {
  patches = [ patch ];
  postPatch = ''
    substituteInPlace jupyter_c_kernel/kernel.py \
      --replace "'gcc'" "'${gccOffload}/bin/gcc'"
    substituteInPlace jupyter_c_kernel/kernel.py \
      --replace "'g++'" "'${gccOffload}/bin/g++'"
  '';
})