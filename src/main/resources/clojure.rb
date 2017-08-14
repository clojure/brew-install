class Clojure < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  url "https://download.clojure.org/install/brew/install-clj-${project.version}.tar.gz"
  sha256 "SHA"

  bottle :unneeded

  depends_on :java => "1.7+"
  depends_on "rlwrap"

  def install
    prefix.install "install-clj-${project.version}.jar"
    prefix.install "clj.props"
    inreplace "install-clj", /PREFIX/, "#{prefix}"
    bin.install "install-clj"
    bin.install "clj"
  end

  test do
    ENV.java_cache
    system "#{bin}/clj", "-e", "nil"
  end
end
