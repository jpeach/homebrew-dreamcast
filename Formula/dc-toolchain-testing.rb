class DcToolchainTesting < Formula
  desc "Dreamcast compilation toolchain (testing)"
  homepage "https://github.com/KallistiOS/KallistiOS/tree/master/utils/dc-chain"
  url "https://github.com/KallistiOS/KallistiOS.git", revision: "fb1d7ec"
  version "2022.05.10"
  license "BSD-3-Clause"

  keg_only "it conflicts with other compilation toolchains"

  depends_on "libelf" => [:build]
  depends_on "xz" => [:build]

  uses_from_macos "bzip2"
  uses_from_macos "curl"

  def install
    Dir.chdir("utils/dc-chain") do
      File.rename("config.mk.testing.sample", "config.mk")

      inreplace "config.mk" do |s|
        s.gsub!(/^#?force_downloader=.*/, "force_downloader=curl") # macOS already has curl
        s.gsub!(/^#?download_protocol=.*/, "download_protocol=https") # macOS already has curl
        s.gsub!(/^#?pass2_languages=.*/, "pass2_languages=c,c++") # Most users only need C and C++, not Objective-C
        # The dc-chain build system isn't parallel-safe, at all.
        s.gsub!(/^#?makejobs=.*/, "makejobs=")
        s.gsub!(/^#?toolchains_base=.*/, "toolchains_base=#{prefix}")
        s.gsub!(/^#?install_mode=.*/, "install_mode=install-strip")
      end

      inreplace "scripts/common.sh" do |s|
        s.gsub!(/ftp.gnu.org/, "ftpmirror.gnu.org")
      end

      inreplace "scripts/init.mk" do |s|
        s.gsub!(/curl_cmd=curl .*/, "curl_cmd=curl --fail --location -C - -O")
      end

      # The download script assumes exact character counts
      # to edit the command. We chanced that in the `curl_cmd`
      # edit above, so clobber it to fix it up.
      inreplace "download.sh" do |s|
        s.gsub!(/WEB_DOWNLOADER=.*/, "WEB_DOWNLOADER=\"curl --fail --location\"")
      end

      system "cat", "config.mk"

      # The dc-chain build system isn't parallel-safe, at all.
      ENV.deparallelize

      system "./download.sh"
      system "./unpack.sh"
      system "make", "patch"
      system "make", "build"
      system "make", "gdb"
    end

    # Generate a script that can be sourced to set the environment
    # variables that the KallistiOS build system needs to use this
    # toolchain.
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