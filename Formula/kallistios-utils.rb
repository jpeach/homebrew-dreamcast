class KallistiosUtils < Formula
  desc "Host-side Dreamcast build utilities from KallistiOS"
  homepage "http://gamedev.allusion.net/softprj/kos/"
  url "https://github.com/KallistiOS/KallistiOS/archive/308a1bb.tar.gz"
  version "2023.05.19"
  sha256 "15e16822f3843b3cd6d4fdc19f898de3c14c7503dfc70bba8899fc7dae6fbba5"
  license ""

  def install
    system "make", "-C", "utils/genromfs"
    bin.install "utils/genromfs/genromfs"
    bin.install "utils/bin2o/bin2o"
  end

  test do
    system "#{bin}/bin2o" # Successfully emit help.
    system "#{bin}/genfomfs", "-h" # Successfully emit help.
  end
end
