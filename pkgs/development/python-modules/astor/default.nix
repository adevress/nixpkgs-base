{ stdenv, isPy3k, buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "astor";
  version = "0.6.2";
  name = "${pname}-${version}";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0pdp1db2l45m8ff9vk7lag11g32aqn0cqkfc4nqsqd6qc8ljwvgz";
  };

  meta = with stdenv.lib; {
    description = "Library for reading, writing and rewriting python AST";
    homepage = https://github.com/berkerpeksag/astor;
    license = licenses.bsd3;
    maintainers = with maintainers; [ nixy ];
  };

  doCheck = !isPy3k;
}
