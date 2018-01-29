{ stdenv, ensureNewerSourcesHook, cmake, pkgconfig
, which, git
, boost, python2Packages
, libxml2, zlib
, openldap, lttngUst
, babeltrace, gperf
, cunit

# Optional Dependencies
, snappy ? null, yasm ? null, fcgi ? null, expat ? null
, curl ? null, fuse ? null, libibverbs ? null, librdmacm ? null
, libedit ? null, libatomic_ops ? null, kinetic-cpp-client ? null
, rocksdb ? null, libs3 ? null

# Mallocs
, jemalloc ? null, gperftools ? null

# Crypto Dependencies
, cryptopp ? null
, nss ? null, nspr ? null

# Linux Only Dependencies
, linuxHeaders, libuuid, udev, keyutils, libaio ? null, libxfs ? null
, zfs ? null

# Version specific arguments
, version, src, patches ? [], buildInputs ? []
, ...
}:

# We must have one crypto library
assert cryptopp != null || (nss != null && nspr != null);

with stdenv;
with stdenv.lib;
let

  shouldUsePkg = pkg_: let pkg = (builtins.tryEval pkg_).value;
    in if lib.any (x: x == system) (pkg.meta.platforms or [])
      then pkg else null;

  optSnappy = shouldUsePkg snappy;
  optYasm = shouldUsePkg yasm;
  optFcgi = shouldUsePkg fcgi;
  optExpat = shouldUsePkg expat;
  optCurl = shouldUsePkg curl;
  optFuse = shouldUsePkg fuse;
  optLibibverbs = shouldUsePkg libibverbs;
  optLibrdmacm = shouldUsePkg librdmacm;
  optLibedit = shouldUsePkg libedit;
  optLibatomic_ops = shouldUsePkg libatomic_ops;
  optKinetic-cpp-client = shouldUsePkg kinetic-cpp-client;
  optRocksdb = shouldUsePkg rocksdb;
  optLibs3 = if versionAtLeast version "10.0.0" then null else shouldUsePkg libs3;

  optJemalloc = shouldUsePkg jemalloc;
  optGperftools = shouldUsePkg gperftools;

  optCryptopp = shouldUsePkg cryptopp;
  optNss = shouldUsePkg nss;
  optNspr = shouldUsePkg nspr;

  optLibaio = shouldUsePkg libaio;
  optLibxfs = shouldUsePkg libxfs;
  optZfs = shouldUsePkg zfs;

  hasServer = optSnappy != null;
  hasMon = hasServer;
  hasMds = hasServer;
  hasOsd = hasServer;
  hasRadosgw = optFcgi != null && optExpat != null && optCurl != null && optLibedit != null;

  hasRocksdb = versionAtLeast version "9.0.0" && optRocksdb != null;

  # TODO: Reenable when kinetic support is fixed
  #hasKinetic = versionAtLeast version "9.0.0" && optKinetic-cpp-client != null;
  hasKinetic = false;

  # Malloc implementation (can be jemalloc, tcmalloc or null)
  malloc = if optJemalloc != null then optJemalloc else optGperftools;

  # We prefer nss over cryptopp
  cryptoStr = if optNss != null && optNspr != null then "nss" else
    if optCryptopp != null then "cryptopp" else "none";
  cryptoLibsMap = {
    nss = [ optNss optNspr ];
    cryptopp = [ optCryptopp ];
    none = [ ];
  };

  ceph-python-env = python2Packages.python.withPackages (ps: [ 
	ps.sphinx
	ps.flask
	ps.argparse
	ps.cython 
	ps.setuptools_pymod
	ps.pip
	]);

in
stdenv.mkDerivation {
  name="ceph-${version}";

  inherit src;

  patches = [ 
    ./0001-kv-RocksDBStore-API-break-additional.patch   
  ];

  nativeBuildInputs = [
    cmake
    pkgconfig which git
    (ensureNewerSourcesHook { year = "1980"; })
  ];
  
  buildInputs = buildInputs ++ cryptoLibsMap.${cryptoStr} ++ [
    boost ceph-python-env libxml2 optYasm optLibatomic_ops optLibs3 
    malloc zlib openldap lttngUst babeltrace gperf cunit
  ] ++ optionals stdenv.isLinux [
    linuxHeaders libuuid udev keyutils optLibaio optLibxfs optZfs
  ] ++ optionals hasServer [
    optSnappy
  ] ++ optionals hasRadosgw [
    optFcgi optExpat optCurl optFuse optLibedit
  ] ++ optionals hasRocksdb [
    optRocksdb
  ] ++ optionals hasKinetic [
    optKinetic-cpp-client
  ];
  
  # rip off submodule that interfer with system libs
  preConfigure =''
	rm -rf src/boost
	rm -rf src/rocksdb
	
	# require LD_LIBRARY_PATH for cython to find internal dep
	export LD_LIBRARY_PATH="$PWD/build/lib:$LD_LIBRARY_PATH"
	
	# requires setuptools due to embedded in-cmake setup.py usage
	export PYTHONPATH="${python2Packages.setuptools_pymod}/lib/python2.7/site-packages/:$PYTHONPATH"
  '';

  cmakeFlags = [ 
    "-DENABLE_GIT_VERSION=OFF"
    "-DWITH_SYSTEM_BOOST=ON"
    "-DWITH_SYSTEM_ROCKSDB=ON"
    "-DWITH_LEVELDB=OFF"
    
    # enforce shared lib
    "-DBUILD_SHARED_LIBS=ON"
    
    # disable cephfs, broken for now
    "-DWITH_CEPHFS=OFF"
    "-DWITH_LIBCEPHFS=OFF"
  ];

  enableParallelBuilding = true;

  meta = {
    homepage = http://ceph.com/;
    description = "Distributed storage system";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ ak wkennington ];
    platforms = platforms.unix;
  };

  passthru.version = version;
}
