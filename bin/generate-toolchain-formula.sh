#! /usr/bin/env bash
# shellcheck disable=SC1039

set -o errexit
set -o pipefail
set -o nounset

WORKDIR="$(mktemp -d)"
readonly WORKDIR

# KallistiOS git revision.
readonly REVISION="308a1bb"

# Formula version, should match date of the Git revision.
VERSION="2023.05.19"
readonly VERSION

KOS_ARCHIVE_SHA=
KOS_ARCHIVE_URL=https://github.com/KallistiOS/KallistiOS/archive/${REVISION}.tar.gz

echo "Fetching ${KOS_ARCHIVE_URL}" 1>&2
curl --location --fail -# -o "${WORKDIR}/kos.tgz" "${KOS_ARCHIVE_URL}"

KOS_ARCHIVE_SHA=$(sha256sum "${WORKDIR}/kos.tgz" | awk '{print $1}')
readonly KOS_ARCHIVE_SHA KOS_ARCHIVE_URL

# NOTE: assumes GNU tar.
tar --strip-components=1 --directory="${WORKDIR}" -xzf "${WORKDIR}/kos.tgz"

for variant in "testing" "stable" "legacy" ; do
  echo "Writing Formula/dc-toolchain-${variant}.rb" 1>&2

  exec >"Formula/dc-toolchain-${variant}.rb"

  cat <<EOF
class DcToolchain${variant^} < Formula
  desc "Dreamcast compilation toolchain (${variant})"
  homepage "https://github.com/KallistiOS/KallistiOS/tree/master/utils/dc-chain"
  url "${KOS_ARCHIVE_URL}"
  version "${VERSION}"
  sha256 "${KOS_ARCHIVE_SHA}"
  license "BSD-3-Clause"
  keg_only "it conflicts with other compilation toolchains"

  depends_on "libelf" => [:build]
  depends_on "xz" => [:build]

  uses_from_macos "bzip2"
  uses_from_macos "curl"
EOF


  # Generate a resources fragment for this variant.
  (
    cd "${WORKDIR}/utils/dc-chain"

    ln -sf config.mk.${variant}.sample config.mk

    # shellcheck disable=SC1091
    source scripts/common.sh > /dev/null

    # Hash of name to URL, for deduplication.
    declare -A resources

    for prefix in "SH_BINUTILS" "SH_GCC" "NEWLIB" "ARM_BINUTILS" "ARM_GCC" "GDB" ; do
      url="${prefix}_TARBALL_URL"
      filename=$(basename "${!url}")
      resources["${filename}"]="${!url}"
    done

    for r in "${!resources[@]}" ; do
      cat <<EOF
  resource "${r}" do
    url "${resources[$r]}"
  end
EOF
    done
  )

  cat <<EOF
  def install
    Dir.chdir("utils/dc-chain") do
      File.rename("config.mk.${variant}.sample", "config.mk")

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
EOF

done
