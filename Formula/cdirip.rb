class Cdirip < Formula
  desc "A program for extracting tracks from a CDI (DiscJuggler) image"
  homepage "https://github.com/jozip/cdirip"
  url "https://github.com/jozip/cdirip.git"
  version "0.6.4"
  sha256 "5fd02b00b6bba10e801d2f57a8558820c2e4f833d806bb05269b48394e20648c"
  license "GPL-2.0-or-later"

  def install
    system "make", "CC=#{ENV.cc}", "CFLAGS=-Os", "PREFIX=#{prefix}", "cdirip"
    bin.install "cdirip" => "cdirip"
  end
end
