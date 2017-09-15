class Clojure < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  url "https://download.clojure.org/install/brew/clojure-scripts-1.8.0.138.tar.gz"
  sha256 "c6c0d4f83989b626bbbb522a905121ace48e5a5d42a606cca70643efb681bb9e"

  devel do
    url "https://download.clojure.org/install/brew/clojure-scripts-${project.version}.tar.gz"
    sha256 "SHA"
    version "${project.version}"
  end

  bottle :unneeded

  depends_on :java => "1.7+"
  depends_on "rlwrap"

  def install
    system "./install.sh", prefix
  end

  test do
    system("#{bin}/clj -e nil")
    %w[clojure clj].each do |clj|
      assert_equal "2", shell_output("#{bin}/#{clj} -e \"(+ 1 1)\"").strip
    end
  end
end
