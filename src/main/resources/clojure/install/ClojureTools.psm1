function Get-StringHash($str) {
  $md5 = new-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
  $utf8 = new-object -TypeName System.Text.UTF8Encoding
  return [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($str)))
}

function Test-NewerFile($file1, $file2) {
  if (!(Test-Path $file1)) {
    return $FALSE
  }
  if (!(Test-Path $file2)) {
    return $TRUE
  }
  $mod1 = (Get-ChildItem $file1).LastWriteTimeUtc
  $mod2 = (Get-ChildItem $file2).LastWriteTimeUtc
  return $mod1 -gt $mod2
}

function Invoke-Clojure {
  $ErrorActionPreference = 'Stop'

  # Set dir containing the installed files
  $InstallDir = $PSScriptRoot
  $Version = '${project.version}'
  $ToolsCp = "$InstallDir\clojure-tools-$Version.jar"

  # Extract opts
  $PrintClassPath = $FALSE
  $Describe = $FALSE
  $Verbose = $FALSE
  $Trace = $FALSE
  $Force = $FALSE
  $Repro = $FALSE
  $Tree = $FALSE
  $Pom = $FALSE
  $Prep = $FALSE
  $Help = $FALSE
  $JvmOpts = @()
  $ResolveAliases = @()
  $ClasspathAliases = @()
  $ReplAliases = @()
  $ClojureArgs = @()
  $Mode = "repl"

  $params = $args
  while ($params.Count -gt 0) {
    $arg, $params = $params
    if ($arg -ceq '-version') {
      Write-Error "Clojure CLI version $Version"
      return
    } elseif ($arg -ceq '--version') {
      Write-Output "Clojure CLI version $Version"
      return
    } elseif ($arg.StartsWith('-J')) {
      $JvmOpts += $arg.Substring(2)
    } elseif ($arg.StartsWith('-R')) {
      Write-Warning "-R is deprecated, use -A with repl, -M for main, or -X for exec"
      $aliases, $params = $params
      if ($aliases) {
        $ResolveAliases += ":$aliases"
      }
    } elseif ($arg.StartsWith('-C')) {
      Write-Warning "-C is deprecated, use -A with repl, -M for main, or -X for exec"
      $aliases, $params = $params
      if ($aliases) {
        $ClassPathAliases += ":$aliases"
      }
    } elseif ($arg.StartsWith('-O')) {
      Write-Error "-O is no longer supported, use -A with repl, -M for main, or -X for exec"
      return
    } elseif ($arg -ceq '-M') {
      $Mode = "main"
      $ClojureArgs += $params
      break
    } elseif ($arg -ceq '-M:') {
      $Mode = "main"
      $kw, $params = $params
      $MainAliases = ":$kw"
      $ClojureArgs += $params
      break
    } elseif ($arg.StartsWith('-T')) {
      Write-Error "-T is no longer supported, use -A with repl, -M for main, or -X for exec"
      return
    } elseif ($arg.StartsWith('-A')) {
      $aliases, $params = $params
      if ($aliases) {
        $ReplAliases += ":$aliases"
      }
    } elseif ($arg -ceq '-X') {
      $Mode = "exec"
      $ClojureArgs += $params
      break
    } elseif ($arg -ceq '-X:') {
      $Mode = "exec"
      $kw, $params = $params
      $ExecAliases = ":$kw"
      $ClojureArgs += $params
      break
    } elseif ($arg -ceq '-P') {
      $Prep = $TRUE
    } elseif ($arg -ceq '-Sdeps') {
      $DepsData, $params = $params
    } elseif ($arg -ceq '-Scp') {
      $ForceCP, $params = $params
    } elseif ($arg -ceq '-Spath') {
      $PrintClassPath = $TRUE
    } elseif ($arg -ceq '-Sverbose') {
      $Verbose = $TRUE
    } elseif ($arg -ceq '-Sthreads') {
      $Threads, $params = $params
    } elseif ($arg -ceq '-Strace') {
      $Trace = $TRUE
    } elseif ($arg -ceq '-Sdescribe') {
      $Describe = $TRUE
    } elseif ($arg -ceq '-Sforce') {
      $Force = $TRUE
    } elseif ($arg -ceq '-Srepro') {
      $Repro = $TRUE
    } elseif ($arg -ceq '-Stree') {
      $Tree = $TRUE
    } elseif ($arg -ceq '-Spom') {
      $Pom = $TRUE
    } elseif ($arg -ceq '-Sresolve-tags') {
      Write-Error "Option changed, use: clj -X:deps git-resolve-tags"
      return
    } elseif ($arg.StartsWith('-S')) {
      Write-Error "Invalid option: $arg"
      return
    } elseif ($arg -in '-h', '--help', '-?') {
      if ($MainAliases -or $AllAliases) {
        $ClojureArgs += $arg, $params
        break
      } else {
        $Help = $TRUE
      }
    } elseif ($arg -eq '--') {
      $ClojureArgs += $params
      break
    } else {
      $ClojureArgs += $arg, $params
      break
    }
  }

  # Find java executable
  $JavaCmd = (Get-Command java -ErrorAction SilentlyContinue).Path
  if (-not $JavaCmd) {
    $CandidateJavas = "$env:JAVA_HOME\bin\java.exe", "$env:JAVA_HOME\bin\java"
    $JavaCmd = $CandidateJavas | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not ($env:JAVA_HOME -and $JavaCmd)) {
      Write-Error "Couldn't find 'java'. Please set JAVA_HOME."
      return
    }
  }

  if ($Help) {
    Write-Host @'
Version: ${project.version}

You use the Clojure tools ('clj' or 'clojure') to run Clojure programs
on the JVM, e.g. to start a REPL or invoke a specific function with data.
The Clojure tools will configure the JVM process by defining a classpath
(of desired libraries), an execution environment (JVM options) and
specifying a main class and args.

Using a deps.edn file (or files), you tell Clojure where your source code
resides and what libraries you need. Clojure will then calculate the full
set of required libraries and a classpath, caching expensive parts of this
process for better performance.

The internal steps of the Clojure tools, as well as the Clojure functions
you intend to run, are parameterized by data structures, often maps. Shell
command lines are not optimized for passing nested data, so instead you
will put the data structures in your deps.edn file and refer to them on the
command line via 'aliases' - keywords that name data structures.

'clj' and 'clojure' differ in that 'clj' has extra support for use as a REPL
in a terminal, and should be preferred unless you don't want that support,
then use 'clojure'.

Usage:
  Start a REPL   clj     [clj-opt*] [-Aaliases] [init-opt*]
  Exec function  clojure [clj-opt*] -X[aliases] [a/fn] [kpath v]*
  Run main       clojure [clj-opt*] -M[aliases] [init-opt*] [main-opt] [arg*]
  Prepare        clojure [clj-opt*] -P [other exec opts]

exec-opts:
  -Aaliases      Use concatenated aliases to modify classpath
  -X[aliases]    Use concatenated aliases to modify classpath or supply exec fn/args
  -M[aliases]    Use concatenated aliases to modify classpath or supply main opts
  -P             Prepare deps - download libs, cache classpath, but don't exec

clj-opts:
  -Jopt          Pass opt through in java_opts, ex: -J-Xmx512m
  -Sdeps EDN     Deps data to use as the final deps file
  -Spath         Compute classpath and echo to stdout only
  -Spom          Generate (or update) pom.xml with deps and paths
  -Stree         Print dependency tree
  -Scp CP        Do NOT compute or cache classpath, use this one instead
  -Srepro        Use only the local deps.edn (ignore other config files)
  -Sforce        Force recomputation of the classpath (don't use the cache)
  -Sverbose      Print important path info to console
  -Sdescribe     Print environment and command parsing info as data
  -Sthreads      Set specific number of download threads
  -Strace        Write a trace.edn file that traces deps expansion
  --             Stop parsing dep options and pass remaining arguments to clojure.main
  --version      Print the version to stdout and exit
  -version       Print the version to stderr and exit

init-opt:
  -i, --init path     Load a file or resource
  -e, --eval string   Eval exprs in string; print non-nil values
  --report target     Report uncaught exception to "file" (default), "stderr", or "none"

main-opt:
  -m, --main ns-name  Call the -main function from namespace w/args
  -r, --repl          Run a repl
  path                Run a script from a file or resource
  -                   Run a script from standard input
  -h, -?, --help      Print this help message and exit

Programs provided by :deps alias:
 -X:deps mvn-install       Install a maven jar to the local repository cache
 -X:deps git-resolve-tags  Resolve git coord tags to shas and update deps.edn

For more info, see:
  https://clojure.org/guides/deps_and_cli
  https://clojure.org/reference/repl_and_main
'@
    return
  }

  # Determine user config directory
  if ($env:CLJ_CONFIG) {
    $ConfigDir = $env:CLJ_CONFIG
  } elseif ($env:HOME) {
    $ConfigDir = "$env:HOME\.clojure"
  } else {
    $ConfigDir = "$env:USERPROFILE\.clojure"
  }

  # If user config directory does not exist, create it
  if (!(Test-Path "$ConfigDir")) {
    New-Item -Type Directory "$ConfigDir" | Out-Null
  }
  if (!(Test-Path "$ConfigDir\deps.edn")) {
    Copy-Item "$InstallDir\example-deps.edn" "$ConfigDir\deps.edn"
  }

  # Determine user cache directory
  if ($env:CLJ_CACHE) {
    $UserCacheDir = $env:CLJ_CACHE
  } else {
    $UserCacheDir = "$ConfigDir\.cpcache"
  }

  # Chain deps.edn in config paths. repro=skip config dir
  $ConfigProject='deps.edn'
  if ($Repro) {
    $ConfigPaths = "$InstallDir\deps.edn", 'deps.edn'
  } else {
    $ConfigUser = "$ConfigDir\deps.edn"
    $ConfigPaths = "$InstallDir\deps.edn", "$ConfigDir\deps.edn", 'deps.edn'
  }
  $ConfigStr = $ConfigPaths -join ','

  # Determine whether to use user or project cache
  if (Test-Path deps.edn) {
    $CacheDir = '.cpcache'
  } else {
    $CacheDir = $UserCacheDir
  }

  # Construct location of cached classpath file
  $CacheKey = "$($ResolveAliases -join '')|$($ClassPathAliases -join '')|$($ReplAliases -join '')|$($JvmAliases -join '')|$ExecAliases|$MainAliases|$DepsData|$($ConfigPaths -join '|')"
  $CacheKeyHash = (Get-StringHash $CacheKey) -replace '-', ''

  $LibsFile = "$CacheDir\$CacheKeyHash.libs"
  $CpFile = "$CacheDir\$CacheKeyHash.cp"
  $JvmFile = "$CacheDir\$CacheKeyHash.jvm"
  $MainFile = "$CacheDir\$CacheKeyHash.main"
  $BasisFile = "$CacheDir\$CacheKeyHash.basis"

  # Print paths in verbose mode
  if ($Verbose) {
    Write-Output @"
version      = $Version
install_dir  = $InstallDir
config_dir   = $ConfigDir
config_paths = $ConfigPaths
cache_dir    = $CacheDir
cp_file      = $CpFile
"@
  }

  # Check for stale classpath file
  $Stale = $FALSE
  if ($Force -or $Trace -or $Tree -or $Prep -or !(Test-Path $CpFile)) {
    $Stale = $TRUE
  } elseif ($ConfigPaths | Where-Object { Test-NewerFile $_ $CpFile }) {
    $Stale = $TRUE
  }

  # Make tools args if needed
  if ($Stale -or $Pom) {
    $ToolsArgs = @()
    if ($DepsData) {
      $ToolsArgs += '--config-data'
      $ToolsArgs += $DepsData
    }
    if ($ResolveAliases) {
      $ToolsArgs += "-R$($ResolveAliases -join '')"
    }
    if ($ClassPathAliases) {
      $ToolsArgs += "-C$($ClassPathAliases -join '')"
    }
    if ($MainAliases) {
      $ToolsArgs += "-M$MainAliases"
    }
    if ($ReplAliases) {
      $ToolsArgs += "-A$($ReplAliases -join '')"
    }
    if ($ExecAliases) {
      $ToolsArgs += "-X$ExecAliases"
    }
    if ($ForceCp) {
      $ToolsArgs += '--skip-cp'
    }
    if ($Threads) {
      $ToolsArgs += '--threads'
      $ToolsArgs += $Threads
    }
    if ($Trace) {
      $ToolsArgs += '--trace'
    }
    if ($Tree) {
      $ToolsArgs += '--tree'
    }
  }

  # If stale, run make-classpath to refresh cached classpath
  if ($Stale -and (-not $Describe)) {
    if ($Verbose) {
      Write-Host "Refreshing classpath"
    }
    & $JavaCmd -classpath $ToolsCp clojure.main -m clojure.tools.deps.alpha.script.make-classpath2 --config-user $ConfigUser --config-project $ConfigProject --basis-file $BasisFile --libs-file $LibsFile --cp-file $CpFile --jvm-file $JvmFile --main-file $MainFile @ToolsArgs
    if ($LastExitCode -ne 0) {
      return
    }
  }

  if ($Describe) {
    $CP = ''
  } elseif ($ForceCp) {
    $CP = $ForceCp
  } else {
    $CP = Get-Content $CpFile
  }

  if ($Prep) {
    # Already done
  } elseif ($Pom) {
    & $JavaCmd -classpath $ToolsCp clojure.main -m clojure.tools.deps.alpha.script.generate-manifest2 --config-user $ConfigUser --config-project $ConfigProject --gen=pom @ToolsArgs
  } elseif ($PrintClassPath) {
    Write-Output $CP
  } elseif ($Describe) {
    $PathVector = ($ConfigPaths | ForEach-Object { "`"$_`"" }) -join ' '
    Write-Output @"
{:version "$Version"
 :config-files [$PathVector]
 :config-user "$ConfigUser"
 :config-project "$ConfigProject"
 :install-dir "$InstallDir"
 :config-dir "$ConfigDir"
 :cache-dir "$CacheDir"
 :force $Force
 :repro $Repro
 :main-aliases "$main_aliases"
 :repl-aliases "$repl_aliases"
 :exec-aliases "$exec_aliases"}
"@
  } elseif ($Tree) {
    # Already done
  } elseif ($Trace) {
    Write-Host "Wrote trace.edn"
  } else {
    if (Test-Path $JvmFile) {
      $JvmCacheOpts = @(Get-Content $JvmFile)
    }

    if ($Mode -eq 'exec') {
      $ExecArgs=@()
      if ($ExecAliases) {
        $ExecArgs += '--aliases'
        $ExecArgs += $ExecAliases
      }
      & $JavaCmd @JvmOpts "-Dclojure.basis=$BasisFile" -classpath "$CP;$InstallDir/exec.jar" clojure.main -m clojure.run.exec @ExecArgs @ClojureArgs
    } else {
      if (Test-Path $MainFile) {
        # TODO this seems dangerous
        $MainCacheOpts = @(Get-Content $MainFile) -replace '"', '\"'
      }
      if ($ClojureArgs.Count -gt 0 -and $Mode -eq 'repl') {
        Write-Warning "When invoking clojure.main, use -M"
      }
      & $JavaCmd @JvmCacheOpts @JvmOpts "-Dclojure.basis=$BasisFile" -classpath $CP clojure.main @MainCacheOpts @ClojureArgs
    }
  }
}

New-Alias -Name clj -Value Invoke-Clojure
New-Alias -Name clojure -Value Invoke-Clojure
