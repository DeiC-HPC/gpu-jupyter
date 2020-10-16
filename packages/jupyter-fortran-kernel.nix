{ python3Packages, gccOffload, writeText }:

let
  patch = writeText "jupyter-c-kernel-patch" ''
--- a/jupyter_c_kernel/kernel.py	2020-10-16 15:23:04.159843942 +0200
+++ b/jupyter_c_kernel/kernel.py	2020-10-16 15:26:08.955834015 +0200
@@ -113,8 +113,8 @@
                                   lambda contents: self._write_to_stderr(contents.decode()))

     def compile_with_gcc(self, source_filename, binary_filename, cflags=None, ldflags=None):
-        cflags = ['-std=c11', '-fPIC', '-shared', '-rdynamic'] + cflags
-        args = ['gcc', source_filename] + cflags + ['-o', binary_filename] + ldflags
+        cflags = ['-fPIC', '-shared', '-rdynamic', '-fopenmp', '-fno-stack-protector', '-foffload=-lm', '-foffload=-misa=sm_35'] + cflags
+        args = ['gfortran', source_filename] + cflags + ['-o', binary_filename] + ldflags
         return self.create_jupyter_subprocess(args)

     def _filter_magics(self, code):
@@ -143,7 +143,7 @@

         magics = self._filter_magics(code)

-        with self.new_temp_file(suffix='.c') as source_file:
+        with self.new_temp_file(suffix='.f') as source_file:
             source_file.write(code)
             source_file.flush()
             with self.new_temp_file(suffix='.out') as binary_file:
@@ -153,7 +153,7 @@
                 p.write_contents()
                 if p.returncode != 0:  # Compilation failed
                     self._write_to_stderr(
-                            "[C kernel] GCC exited with code {}, the executable will not be executed".format(
+                            "[Fortran kernel] GCC exited with code {}, the executable will not be executed".format(
                                     p.returncode))
                     return {'status': 'ok', 'execution_count': self.execution_count, 'payload': [],
                             'user_expressions': {}}
@@ -164,7 +164,7 @@
         p.write_contents()

         if p.returncode != 0:
-            self._write_to_stderr("[C kernel] Executable exited with code {}".format(p.returncode))
+            self._write_to_stderr("[Fortran kernel] Executable exited with code {}".format(p.returncode))
         return {'status': 'ok', 'execution_count': self.execution_count, 'payload': [], 'user_expressions': {}}

     def do_shutdown(self, restart):
  '';
in
python3Packages.jupyter-c-kernel.overrideAttrs (attrs: {
  patches = [ patch ];
  postPatch = ''
    substituteInPlace jupyter_c_kernel/kernel.py \
      --replace "'gcc'" "'${gccOffload}/bin/gcc'"
    substituteInPlace jupyter_c_kernel/kernel.py \
      --replace "'gfortran'" "'${gccOffload}/bin/gfortran'"
  '';
})
