class Clojure < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  url "http://cdn.cognitect.com/brew/clojure-install-bundle-${project.version}.tar.gz"
  sha256 "SHA"

  bottle :unneeded

  depends_on :java => "1.7+"
  depends_on "rlwrap"

  def install
    prefix.install "clojure-install-${project.version}.jar"
    inreplace "install-clj.sh", /INSTALL_JAR/, "#{prefix}/clojure-install-${project.version}.jar"
    bin.install "install-clj.sh" => "install-clj"
    bin.install "clj.sh" => "clj"
    system "/bin/sh", "#{bin}/install-clj"
  end

  test do
    ENV.java_cache
    system "#{bin}/clj", "-e", "nil"
  end
end
