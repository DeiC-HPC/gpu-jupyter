{ lib
, python3Packages
, gccOffload
, writeText
, flags
, compilerName
, languageName
, fileExtension
}:
let
  fixedFlags = lib.strings.concatMapStringsSep ", " (s: "'" + s + "'") flags;
  patch = writeText "jupyter-c-kernel-patch" ''
    diff -Naur jupyter_c_kernel-1.2.2/jupyter_c_kernel/kernel.py jupyter_c_kernel-1.2.2-new/jupyter_c_kernel/kernel.py
    --- jupyter_c_kernel-1.2.2/jupyter_c_kernel/kernel.py	2018-01-24 11:05:46.000000000 +0100
    +++ jupyter_c_kernel-1.2.2-new/jupyter_c_kernel/kernel.py	2020-10-21 15:33:48.762021941 +0200
    @@ -14,7 +14,7 @@
         A subprocess that allows to read its stdout and stderr in real time
         """

    -    def __init__(self, cmd, write_to_stdout, write_to_stderr):
    +    def __init__(self, cmd, write_to_stdout, write_to_stderr, **kwargs):
             """
             :param cmd: the command to execute
             :param write_to_stdout: a callable that will be called with chunks of data from stdout
    @@ -23,7 +23,7 @@
             self._write_to_stdout = write_to_stdout
             self._write_to_stderr = write_to_stderr

    -        super().__init__(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0)
    +        super().__init__(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, bufsize=0, **kwargs)

             self._stdout_queue = Queue()
             self._stdout_thread = Thread(target=RealTimeSubprocess._enqueue_output, args=(self.stdout, self._stdout_queue))
    @@ -107,14 +107,15 @@
         def _write_to_stderr(self, contents):
             self.send_response(self.iopub_socket, 'stream', {'name': 'stderr', 'text': contents})

    -    def create_jupyter_subprocess(self, cmd):
    +    def create_jupyter_subprocess(self, cmd, **kwargs):
             return RealTimeSubprocess(cmd,
                                       lambda contents: self._write_to_stdout(contents.decode()),
    -                                  lambda contents: self._write_to_stderr(contents.decode()))
    +                                  lambda contents: self._write_to_stderr(contents.decode()),
    +                                  **kwargs)

         def compile_with_gcc(self, source_filename, binary_filename, cflags=None, ldflags=None):
    -        cflags = ['-std=c11', '-fPIC', '-shared', '-rdynamic'] + cflags
    -        args = ['gcc', source_filename] + cflags + ['-o', binary_filename] + ldflags
    +        cflags = ['-fPIC', '-shared', '-rdynamic', ${fixedFlags}] + cflags
    +        args = ['${gccOffload}/bin/${compilerName}', source_filename] + cflags + ['-o', binary_filename] + ldflags
             return self.create_jupyter_subprocess(args)

         def _filter_magics(self, code):
    @@ -143,7 +144,7 @@

             magics = self._filter_magics(code)

    -        with self.new_temp_file(suffix='.c') as source_file:
    +        with self.new_temp_file(suffix='.${fileExtension}') as source_file:
                 source_file.write(code)
                 source_file.flush()
                 with self.new_temp_file(suffix='.out') as binary_file:
    @@ -153,18 +154,20 @@
                     p.write_contents()
                     if p.returncode != 0:  # Compilation failed
                         self._write_to_stderr(
    -                            "[C kernel] GCC exited with code {}, the executable will not be executed".format(
    +                            "[${languageName} kernel] ${compilerName} exited with code {}, the executable will not be executed".format(
                                         p.returncode))
                         return {'status': 'ok', 'execution_count': self.execution_count, 'payload': [],
                                 'user_expressions': {}}

    -        p = self.create_jupyter_subprocess([self.master_path, binary_file.name] + magics['args'])
    +        my_env = os.environ.copy()
    +        my_env["LD_LIBRARY_PATH"] = "${gccOffload.cc}/lib:/usr/lib/x86_64-linux-gnu/"
    +        p = self.create_jupyter_subprocess([self.master_path, binary_file.name] + magics['args'], env = my_env)
             while p.poll() is None:
                 p.write_contents()
             p.write_contents()

             if p.returncode != 0:
    -            self._write_to_stderr("[C kernel] Executable exited with code {}".format(p.returncode))
    +            self._write_to_stderr("[${languageName} kernel] Executable exited with code {}".format(p.returncode))
             return {'status': 'ok', 'execution_count': self.execution_count, 'payload': [], 'user_expressions': {}}

         def do_shutdown(self, restart):
  '';
in
python3Packages.jupyter-c-kernel.overrideAttrs (attrs: {
  patches = [ patch ];
  postPatch = ''
    substituteInPlace jupyter_c_kernel/kernel.py \
      --replace "'gcc'" "'${gccOffload}/bin/gcc'"
  '';
})
