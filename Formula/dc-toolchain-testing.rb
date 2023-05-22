class DcToolchainTesting < Formula
  desc "Dreamcast compilation toolchain (testing)"
  homepage "https://github.com/KallistiOS/KallistiOS/tree/master/utils/dc-chain"
  url "https://github.com/KallistiOS/KallistiOS/archive/308a1bb.tar.gz"
  version "2023.05.19"
  sha256 "15e16822f3843b3cd6d4fdc19f898de3c14c7503dfc70bba8899fc7dae6fbba5"
  license "BSD-3-Clause"
  keg_only "it conflicts with other compilation toolchains"

  depends_on "libelf" => [:build]
  depends_on "xz" => [:build]

  uses_from_macos "bzip2"
  uses_from_macos "curl"
  resource "newlib-4.3.0.20230120.tar.gz" do
    url "sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz"
  end
  resource "gcc-13.1.0.tar.xz" do
    url "ftpmirror.gnu.org/gnu/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz"
  end
  resource "gcc-8.5.0.tar.xz" do
    url "ftpmirror.gnu.org/gnu/gcc/gcc-8.5.0/gcc-8.5.0.tar.xz"
  end
  resource "binutils-2.40.tar.xz" do
    url "ftpmirror.gnu.org/gnu/binutils/binutils-2.40.tar.xz"
  end
  resource "gdb-13.1.tar.xz" do
    url "ftpmirror.gnu.org/gnu/gdb/gdb-13.1.tar.xz"
  end
  def install
    Dir.chdir("utils/dc-chain") do
      File.rename("config.mk.testing.sample", "config.mk")

      inreplace "config.mk" do |s|
        s.gsub!(/^#?force_downloader=.*/, "force_downloader=curl") # macOS already has curl
        s.gsub!(/^#?download_protocol=.*/, "download_protocol=https") # macOS already has curl
        s.gsub!(/^#?pass2_languages=.*/, "pass2_languages=c,c++") # Most users only need C and C++, not Objective-C
        # The dc-chain build system isn't parallel-safe, but the component
        # builds should be. Use about half the system CPUs to build.
        s.gsub!(/^#?makejobs=.*/, "makejobs=-j#{(Etc.nprocessors + 1) / 2}")
        s.gsub!(/^#?toolchains_base=.*/, "toolchains_base=#{prefix}")
        s.gsub!(/^#?install_mode=.*/, "install_mode=install-strip")
      end

      inreplace "scripts/common.sh" do |s|
        s.gsub!(/ftp.gnu.org/, "ftpmirror.gnu.org", audit_result=false)
      end

      inreplace "scripts/init.mk" do |s|
        s.gsub!(/curl_cmd=curl .*/, "curl_cmd=curl --fail --location -C - -O")
      end

      # The download script assumes exact character counts
      # to edit the command. We changed that in the "curl_cmd"
      # edit above, so clobber it to fix it up.
      inreplace "download.sh" do |s|
        s.gsub!(/WEB_DOWNLOADER=.*/, "WEB_DOWNLOADER=\"curl --fail --location\"")
      end

      # The dc-chain build system isn't parallel-safe, at all.
      ENV.deparallelize

      # Use private Homebrew API to copy the artifacts out of the download
      # cache. The unpack script needs this because it always deletes the
      # output directoty and extract the archives again.
      resources.each do |r|
        cp r.cached_download, buildpath/"utils/dc-chain/#{r.name}"
      end

      # We don't guarantee to download everything that the build needs, so let
      # the download script check for more artifacts.
      system "./download.sh"

      # Unpack both extracts the archives, and downloads GCC prerequisites.
      system "./unpack.sh"

      system "make", "patch"
      system "make", "build-sh4"
      system "make", "build-arm"
      system "make", "gdb"
    end

    # Generate a script that can be sourced to set the environment
    # variables that the KallistiOS build system needs to use this
    # toolchain.
    ohai "Writing KallistiOS toolchain variables to #{prefix}/kos.env"

    (prefix/"kos.env").write <<~EOF
      export KOS_CC_BASE="#{prefix}/sh-elf"
      export KOS_CC_PREFIX="sh-elf"
      export DC_ARM_BASE="#{prefix}/arm-eabi"
      export DC_ARM_PREFIX="arm-eabi"
    EOF
  end

  test do
    system "#{prefix}/sh-elf/bin/sh-elf-gcc", "--version"
    system "#{prefix}/arm-eabi/bin/arm-eabi-gcc", "--version"
  end
end

# vim: set ft=ruby :
