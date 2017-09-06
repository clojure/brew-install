class Clojure < Formula
  desc "The Clojure Programming Language"
  homepage "https://clojure.org"
  url "https://download.clojure.org/install/brew/clojure-scripts-1.8.0.132.tar.gz"
  sha256 "9e544c830977aa796c750737f2fcee5e8f4be08c081493b9851c4bbb07c7e570"

  devel do
    url "https://download.clojure.org/install/brew/clojure-scripts-${project.version}.tar.gz"
    sha256 "SHA"
    version "${project.version}"
  end

  bottle :unneeded

  depends_on :java => "1.7+"
  depends_on "rlwrap"

  def install
    system("./install.sh #{prefix}")
  end

  def caveats; <<-EOS.undent
      Run `clojure -h` to see Clojure runner options.
      Run `clj` for an interactive Clojure REPL.
    EOS
  end

  test do
    system("#{bin}/clj -e nil")
    %w[clojure clj].each do |clj|
      assert_equal "2", shell_output("#{bin}/#{clj} -e \"(+ 1 1)\"").strip
    end
  end
end
