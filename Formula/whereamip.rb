class Whereamip < Formula
  desc "Menu bar country-flag exit IP, VPN + Private Relay + connectivity awareness"
  homepage "https://github.com/frinsen/whereamip"
  # NOTE: exactly one `url` and one `sha256` line are allowed in this file.
  # .github/workflows/release.yml bumps both via a line-anchored `sed` on
  # every release tag push (matches only the canonical two-space-indented
  # `  url "` / `  sha256 "` lines below); adding a second url/sha256 line
  # (e.g. for a bottle or livecheck block) at that same indentation would get
  # clobbered with the wrong value unless that sed is updated to match.
  url "https://github.com/frinsen/whereamip/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "ec215d17a6c10dea8ca2b7509c4c1368e505512b2c0b0b7289421a74cb49a2d0"
  license "MIT"
  head "https://github.com/frinsen/whereamip.git", branch: "main"

  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    # Install the CLI binary together with its resource bundle so
    # RelayRanges.bundled() can find whereamip_WhereAmIPCore.bundle next to
    # the executable at runtime (Private Relay detection needs it). bin gets
    # a symlink rather than a copy of the binary: verified empirically that
    # Bundle.main.executableURL reports the *symlink* path when invoked as
    # bin/whereamip (does NOT resolve it), but findResourceBundle()'s other
    # candidates — Bundle(for: RelayRangesBundleToken.self).bundleURL /
    # .resourceURL — use dyld's loaded-image path, which *is* the real
    # libexec/cli/whereamip location, so the bundle still resolves. Confirmed
    # by running the actual RelayRanges.bundled() code through a replicated
    # bin-symlink/libexec/cli layout (see final-fix report).
    (libexec/"cli").install ".build/release/whereamip", ".build/release/whereamip_WhereAmIPCore.bundle"
    bin.install_symlink libexec/"cli"/"whereamip"

    # make-app-bundle.sh runs its own `swift build -c release` to assemble
    # WhereAmIP.app. Without --disable-sandbox that inner build fails (EPERM)
    # inside brew's build sandbox. SWIFT_BUILD_FLAGS threads the same flag
    # the outer build used through to the script's build.
    ENV["SWIFT_BUILD_FLAGS"] = "--disable-sandbox"
    system "scripts/make-app-bundle.sh", libexec.to_s
  end

  def caveats
    <<~EOS
      Start the menu bar app with:
        open "#{opt_libexec}/WhereAmIP.app"
      Then enable Settings ▸ Launch at Login inside the app.
      CLI: whereamip status

      If Launch at Login stops working after a brew upgrade, re-toggle it in
      Settings.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/whereamip --version")
  end
end
