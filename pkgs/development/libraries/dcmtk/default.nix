{ stdenv, fetchFromGitHub, unzip, cmake, boost, zlib }:

stdenv.mkDerivation rec {
  name = "dcmtk-${version}";
  version = "3.6.3";

  src = fetchFromGitHub{
    owner = "DCMTK";
    repo = "dcmtk";
    rev = "DCMTK-${version}";
    sha256 = "1m4mqm2wvbpwpmbf1r5sz3ir28rwbh94acn45is1h9wnfj5x6nx8";
  };

  buildInputs = [ cmake boost zlib ];

  meta = with stdenv.lib; {
    description = "This DICOM ToolKit (DCMTK) package consists of source code, documentation and installation instructions for a set of software libraries and applications implementing part of the DICOM/MEDICOM Standard";    homepage = http://assimp.sourceforge.net/;
    license = licenses.mit;
    maintainers = with maintainers; [ jriesmeier ];
    platforms = platforms.linux;
  };
}
