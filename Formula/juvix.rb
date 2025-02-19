class Juvix < Formula
    desc "The Juvix compiler"
    homepage "https://juvix.org"
    url "https://github.com/anoma/juvix.git", branch: "main"
    license "AGPL-3.0-or-later"
    
    stable do
      url "https://github.com/anoma/juvix.git", branch: "main"
      version "0.2.4"
      sha256 "ff30fe9d05710c209ae998fc2762d577a4f7aa15"
    end
    
    head do
      url "https://github.com/anoma/juvix.git", branch: "main"
    end

    livecheck do
      skip "No version information available to check"
    end
  
    option "without-stack", "Do not install Haskell-Stack"
    
    depends_on "make" => :build
    depends_on "llvm" => :build
    depends_on "stack" => :build
  
#     bottle do
#       root_url "https://github.com/anoma/juvix/releases/download/v0.2.4"
#       sha256 cellar: :any_skip_relocation, arm64_monterey: "d89617f8ec50993d7815c14ec4f5fc471329d33d954b5f832bf4e977351ef913"
#       sha256 cellar: :any_skip_relocation, x86_64_monterey: "4d27e0c2f0374caa20ff74682e470110fbd9f61b9859acf0e095487e538d6336"
#     end
    
    def install
      jobs = ENV.make_jobs
      opts = [ "--stack-root", buildpath/".stack" ]
      ENV.deparallelize { system "stack", "-j#{jobs}", "setup", "9.2.4", *opts }
      ENV.prepend_path "PATH", Dir[buildpath/".stack/programs/*/ghc-*/bin"].first
      system "stack", "-j#{jobs}", "build" , *opts
      system "stack", "-j#{jobs}", "--local-bin-path=#{bin}", "install"  , *opts
      share.install Dir["juvix-mode/*"]
      share.install Dir["examples/*"]
    end

    def caveats
      <<~EOS
        =============================== Juvix examples =================================
        To see all the Juvix example files, check out the path:

          #{share}/examples/milestone

        There, you might want to typecheck a Juvix file. For example, run:
        
          juvix typecheck Fibonacci/Fibonacci.juvix

        ============================ Juvix mode for Emacs ==============================
        To install the Juvix mode in Emacs, please add the following lines to the
        configuration file (often at "~/.emacs.d").
          
          (push "#{share}" load-path)
              (require 'juvix-mode)
            
        Restart Emacs for the change to take effect. Open Emacs again and the Juvix mode
        will be activated automatically for files with extension ".juvix".
        
        To typecheck a Juvix file using the keybinding, press "Ctrl-c + Ctrl-l".
        
        In case you're missing Emacs, we recommend you to install it as follows on MacOS:

          brew tap d12frosted/emacs-plus
          brew install emacs-plus@28

        ============================= Juvix VSCode =====================================

        You can find the Juvix-Mode plugin in the VSCode marketplace. Alternatively, you
        can run the following command:

          ext install heliax.juvix-mode
        
        ====================== Install the auto-completion Scripts =====================
        To get the Juvix CLI completions for your shell, run the following:

        * Bash
          juvix --bash-completion-script juvix > ~/.bashrc
        
        * FISH
          juvix --fish-completion-script juvix > ~/.config/fish/completions/juvix.fish
        
        * ZSH 
          juvix --zsh-completion-script juvix > $DIR_IN_FPATH/_juvix
        
        The variable $DIR_IN_FPATH is a directory that is present on the ZSH FPATH
        variable (which you can inspect by running `echo $FPATH` in the shell).
        
        Restart your terminal for the settings to take effect.
        
        ======================== Compile Juvix programs to Wasm ========================  
        To compile Juvix to Wasm, please follow the instructions on the website.
        The requirement are: wasmer, Clang/LLVM, wasi-sdk, and wasm-ld.
        
          https://docs.juvix.org/getting-started/dependencies.html
        
        ============================ Getting more help =================================
        To see all the Juvix commands, run:
          juvix --help

        To check your setup, run:
          juvix doctor

        For more documentation, please check out the Juvix Book website:
          https://docs.juvix.org

        or the Github repository:
          https://github.com/anoma/juvix
       
        or even better, join us on Discord for online support:
          https://discord.gg/PpDqtCjy

        To see these instructions, run:
          brew info juvix
      EOS
    end

    test do
      stdlibtest = testpath/"Fibonacci.juvix"
      stdlibtest.write <<~EOS
      module Fibonacci;
      
      open import Stdlib.Prelude;
      
      fib : ℕ → ℕ → ℕ → ℕ;
      fib zero x1 _ ≔ x1;
      fib (suc n) x1 x2 ≔ fib n x2 (x1 + x2);
      
      fibonacci : ℕ → ℕ;
      fibonacci n ≔ fib n 0 1;

      main : IO;
      main ≔ putStrLn (natToStr (fibonacci 25));
      end;
      EOS
  
      assert_equal "Well done! It type checks\n", shell_output("#{bin}/juvix typecheck #{stdlibtest}")
      # system bin/"juvix", "compile", stdlibtest
      # assert_equal "75025" , shell_output("wasmer  #{testpath}/Fibonacci.wasm")
    end

  end
