class DcloadSerial < Formula
  desc "dcload-serial is the host side of the dcload Sega Dreamcast serial loader."
  homepage "https://github.com/KallistiOS/dcload-serial"
  url "https://github.com/KallistiOS/dcload-serial.git", :revision => "95628f1"
  version "1.0.6"
  sha256 ""
  license "GPL-2.0-or-later"

  depends_on "libelf"

  def install
    system "make", "-C", "host-src/tool",
      "HOSTCC=#{ENV.cc}", "HOSTCFLAGS=-Os", "WITH_BFD=0",
      "dc-tool-ser"
    bin.install "host-src/tool/dc-tool-ser" => "dc-tool-ser"
  end

  test do
    system "#{bin}/dc-tool-ser", "-h"
  end
end
