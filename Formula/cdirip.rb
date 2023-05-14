class Cdirip < Formula
  desc "Program for extracting tracks from a CDI (DiscJuggler) image"
  homepage "https://github.com/jozip/cdirip"
  url "https://github.com/jozip/cdirip.git"
  version "0.6.4"
  license "GPL-2.0-or-later"

  def install
    system "make", "CC=#{ENV.cc}", "CFLAGS=-Os", "PREFIX=#{prefix}", "cdirip"
    bin.install "cdirip" => "cdirip"
  end
end
