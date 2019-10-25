Name:       clojure
Version:    %{VERSION}
Release:    1%{?dist}
Summary:    The Clojure Programming Language

License:    EPL
URL:        https://clojure.org
Source0:    clojure-tools-%{version}.tar.gz

Requires:   bash
Requires:   java

BuildArch:  noarch

%description
Clojure is a dynamic, general-purpose programming language, combining the approachability and interactive development of a scripting language with an efficient and robust infrastructure for multithreaded programming. Clojure is a compiled language, yet remains completely dynamic – every feature supported by Clojure is supported at runtime. Clojure provides easy access to the Java frameworks, with optional type hints and type inference, to ensure that calls to Java can avoid reflection.

Clojure is a dialect of Lisp, and shares with Lisp the code-as-data philosophy and a powerful macro system. Clojure is predominantly a functional programming language, and features a rich set of immutable, persistent data structures. When mutable state is needed, Clojure offers a software transactional memory system and reactive Agent system that ensure clean, correct, multithreaded designs.

I hope you find Clojure's combination of facilities elegant, powerful, practical and fun to use.

Rich Hickey
author of Clojure and CTO Cognitect

%prep

%setup -T -c

%build

%install
mkdir -p "%{buildroot}"
tar -C %{buildroot} -xf %{SOURCE0}
%{buildroot}/clojure-tools/install.sh --prefix %{buildroot}%{_prefix} --local
rm -rf %{buildroot}/clojure-tools

%files
%{_bindir}/clj
%{_bindir}/clojure
%{_libdir}/clojure/deps.edn
%{_libdir}/clojure/example-deps.edn
%{_libdir}/clojure/libexec/clojure-tools-%{version}.jar
%{_mandir}/man1/clj.1
%{_mandir}/man1/clojure.1

%changelog
