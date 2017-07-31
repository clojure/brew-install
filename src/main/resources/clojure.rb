class Clojure < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  url "http://cdn.cognitect.com/brew/brew-install-${project.version}.tar.gz"
  sha256 "SHA"

  bottle :unneeded

  depends_on :java => "1.7+"
  depends_on "rlwrap"

  def install
    prefix.install "clojure-install-${project.version}.jar"
    prefix.install "clj.props"
    inreplace "install-clj.sh", /PREFIX/, "#{prefix}"
    bin.install "install-clj.sh" => "install-clj"
    bin.install "clj"
    system "/bin/sh", "#{bin}/install-clj"
  end

  test do
    ENV.java_cache
    system "#{bin}/clj", "-e", "nil"
  end
end
