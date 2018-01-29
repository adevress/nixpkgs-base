{ callPackage, fetchgit, fetchpatch, ... } @ args:

callPackage ./generic.nix (args // rec {
  version = "12.2.2";

  src = fetchgit {
    url = "https://github.com/ceph/ceph.git";
    rev = "refs/tags/v${version}";
    sha256 = "01anqxyffa8l2lzgyb0dj6fjicfjdx2cq9y1klh24x69gxwkdh00";
  };

  patches = [
    ./fix-pythonpath.patch
    # For building with xfsprogs 4.5.0:
    (fetchpatch {
      url = "https://github.com/ceph/ceph/commit/602425abd5cef741fc1b5d4d1dd70c68e153fc8d.patch";
      sha256 = "1iyf0ml2n50ki800vjich8lvzmcdviwqwkbs6cdj0vqv2nc5ii1g";
    })
  ];
})
