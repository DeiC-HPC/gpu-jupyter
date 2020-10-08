{ nixpkgs, pkgs, callPackage, lib, stdenv, fetchurl, fetchFromGitHub, texinfo, which, gettext, perl, newlib, gmp, mpfr, libmpc, libelf, glibc, cudatoolkit }:

let majorVersion = "10";
    version = "${majorVersion}.2.0";
    gccSrc = fetchurl {
      url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
      sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
    };
    newlibSrc = fetchurl {
      url = "ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz";
      sha256 = "0ricyx792ig2cb2x31b653yb7w7f7mf2111dv5h96lfzmqz9xpaq";
    };
    nvptxSrc = fetchFromGitHub {
      owner = "MentorEmbedded";
      repo = "nvptx-tools";
      rev = "5f6f343a302d620b0868edab376c00b15741e39e";
      sha256 = "0panh7kb4jirci8w626zln36hfjybjzbfnspnrwzrvh8xyaijqaw";
    };
in

stdenv.mkDerivation {
  pname = "mygcc";
  inherit version;

  builder = "${nixpkgs}/pkgs/development/compilers/gcc/builder.sh";
  
  phases = [ "buildPhase" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf ];

  hardeningDisable = [ "format" "pie" ];

  staticCompiler = false;
  noSysDirs = false;

  buildPhase = ''
    mkdir $out
    echo ${nixpkgs} >> $out/foo

    mkdir build-nvptx
    cd build-nvptx
    ${nvptxSrc}/configure --prefix=$out
    make -j8
    make install
    cd ..
    rm -rf build-nvptx

    mkdir newlib && tar -C newlib --strip-components=1 -xf ${newlibSrc}
    mkdir gcc && tar -C gcc --strip-components=1 -xf ${gccSrc}

    ln -s ../newlib/newlib gcc/newlib

    mkdir build-gcc-nvptx
    cd build-gcc-nvptx
    ../gcc/configure --prefix=$out --disable-multilib --disable-bootstrap --enable-languages=c,c++,lto --target=nvptx-none --enable-as-accelerator-for=x86_64-pc-linux-gnu --with-build-time-tools=$out/nvptx-none/bin --disable-sjlj-exceptions --enable-newlib-io-long-long
    make -j8
    make install
    cd ..
    rm -rf build-gcc-nvptx

    rm gcc/newlib

    mkdir build-gcc-offload
    cd build-gcc-offload
    ../gcc/configure --prefix=$out --disable-multilib --disable-bootstrap --enable-languages=c,c++,lto --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=x86_64-pc-linux-gnu --enable-offload-targets=nvptx-none=$out/nvptx-none --with-cuda-driver=${cudatoolkit} --with-native-system-header-dir=${lib.getDev stdenv.cc.libc}/include
    make -j8
    make install
  '';
}