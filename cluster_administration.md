---
title: Cluster Administration
layout: main
---

Welcome to the "hidden" wiki of administering software installations on the Totient
cluster!  This document serves as a catalog of how Totient was setup to use the
glorious, terrifying, mystifying, and stupendously fantastic package manager
[spack](http://spack.readthedocs.io/en/latest/).

To protect his identity, we endearingly refer to the individual who assisted with many
aspects of this setup as SpackMan.  His word is law, even if we did not obey all of his
suggestions.  Thank you, SpackMan.

**TL;DR**
: 1. First, get the [Admin Shell Configurations](#admin-shell-configurations) setup.
  2. Next, try and install things.  The [Syntax](#syntax) section should have enough
     for you to start blindly trying to install things ;)
  3. **NEVER** `install` anything before checking the `spec` (see [Commands](#commands)).
  4. Load the appropriate compiler module for what you just installed, and now execute
     the `update_totient_lmod_db` command.

**Notice**:
: Parts of this document are better written than others.  This is generally proportional
  to how much I understood what was the "right" thing to do.

# Overview
----------------------------------------------------------------------------------------

- [Spack Cheat Sheet](#spack-cheat-sheet)
    - [Understanding Spack](#understanding-spack)
    - [Spack Customization and Configurations](#spack-customization-and-configurations)
    - [Spack Workflow](#spack-workflow)
    - [Admin Shell Configurations](#admin-shell-configurations)
        - [Convenience Startup Scripts](#convenience-startup-scripts)
            - [Bash Profile](#bash-profile)
            - [Bash RC](#bash-rc)
    - [Syntax](#syntax)
        - [Commands](#commands)
        - [Syntax and Examples](#syntax-and-examples)
            - [Versions](#versions)
            - [Compilers](#compilers)
            - [Variants](#variants)
            - [Dependencies](#dependencies)
- [Totient and Spack](#totient-and-spack)
    - [EXTREME CAUTION IS REQUIRED](#extreme-caution-is-required)
    - [Totient Specific Spack Configurations](#totient-specific-spack-configurations)
        - [Considerations for Modules](#considerations-for-modules)
- [Totient and Spack and Lmod](#totient-and-spack-and-lmod)
    - [Brief Overview of Lmod](#brief-overview-of-lmod)
    - [Links Used in Getting Lmod Setup](#links-used-in-getting-lmod-setup)
    - [Totient Lmod Startup and Configurations](#totient-lmod-startup-and-configurations)
        - [Lmod on Startup](#lmod-on-startup)
        - [Lmod Configurations](#lmod-configurations)
            - [The Totient Login Module](#the-totient-login-module)
            - [Relating `spack_all` and `spack_compilers`](#relating-spack_all-and-spack_compilers)
    - [Spack Module Setup](#spack-module-setup)
    - [Regenerating the Spider Cache](#regenerating-the-spider-cache)
- [Debugging](#debugging)
    - [How to Proceed](#how-to-proceed)
    - [The Builtin Knobs Will Not Turn](#the-builtin-knobs-will-not-turn)
        - [Try Compiling Manually](#try-compiling-manually)
        - [Modify the Spack Package](#modify-the-spack-package)
- [Factory Reset](#factory-reset)
- [Future TODO](#future-todo)
    - [Future TODO Notes](#future-todo-notes)

# Spack Cheat Sheet
----------------------------------------------------------------------------------------

## Understanding Spack

The most important thing to understand about `spack` is what goes where.  Generally
speaking, you should **never** modify anything manually underneath the `spack` root
directory.  The only manual changes I have made are for site-specific configurations,
and some hacks to get the Intel 2015 compiler to work.

The second most important thing to understand about `spack`: **do not, under any
circumstances, execute `git pull` if you have installed anything**.  Though you may be
able to acquire new packages that others have added, if anything from the default
variants of a package to the dependencies of a given package change, your installations
may become orphaned, deleted, replaced, or even worse: `spack` may get so confused that
you have no choice but to delete it and start over.  You have been warned.

On a fresh
clone of `spack`, the directory structure is:

```
spack/
├── bin
│   ├── sbang
│   ├── spack
│   └── spack-python
├── etc
│   └── spack
│       └── defaults
├── lib
│   └── spack
│       ├── docs
│       ├── env
│       ├── external
│       ├── llnl
│       └── spack
├── share
│   └── spack
│       ├── csh
│       ├── logo
│       ├── qa
│       ├── setup-env.csh
│       ├── setup-env.sh
│       └── spack-completion.bash
└── var
    └── spack
        ├── gpg
        ├── gpg.mock
        ├── mock_configs
        └── repos
```

`spack/bin`
: The main executable(s).  You can simply run `./bin/spack`, or get your shell setup so
  that `spack` is available as a command.  More on that in the
  [Admin Shell Configurations](#admin-shell-configurations) section.

`spack/etc`
: These are where the site-specific YAML configurations go.

`spack/etc/defaults`
: The default configurations, **never** change.

`spack/lib`
: The core `spack` library.  See `spack/var` below.  This is the code for general
  purpose I/O, concretization, etc.

`spack/share`
: This is where shell utilities, module files, etc are (or get symlinked to from an
  installation).

`spack/opt` (not shown)
: Where all of the installations after compilation end up.

`spack/var`
: The relevant folder here is that this is where the staging area for packages gets
  symlinked so that you can go find out why some package did not install.  The folder
  `spack/var/spack/repos/builtin/packages` are where all of the package definitions are.

## Spack Customization and Configurations

Spack allows for three levels of configuration.  The order in which they are loaded
determines the overall output (where conflicts are concerned).

1. First, the default configurations from `spack/etc/defaults` are loaded.  Some are
   global defaults, some are specific to a given operating system.

2. Next, any `*.yaml` files found in `spack/etc` are loaded.  These will be referred to
   as site-specific configurations.  In our case, we are going to have custom
   `config.yaml` (overall configs, only used for changing where the staging area is),
   `compilers.yaml` (what compilers are available and where they are), and
   `packages.yaml` (default variants for the packages we care about).

3. Last, Spack looks in `$HOME/.spack`.

So in the event that a user has specific customizations that override our site-specific
configurations, the user configurations take precendence.  Hence I **highly** encourage
to keep all Spack configurations as site-specific to avoid hard to understand
discrepancies.

## Spack Workflow

It's worth quickly mentioning the lifecycle of a `spack install` command.

1. The specification of the package to install (hereby called spec) is concretized, and
   dependencies are determined.
2. All dependencies are built (if needed).
3. The source code for the package is downloaded and _staged_.  Staging typically means
   extracting the `.tar.gz` and running `cmake`, `configure`, etc.
4. The `install` phase (as printed on the command line) is then typically going to first
   run `make` and then `make install`.

This is important for us because `/share` has limited space, so I have customized where
the staging area is (since `/tmp` is also very small).  `make install` will put the
files somewhere underneath `spack/opt`, and likely also create symlinks to module files
and put them underneath `spack/share`.

## Admin Shell Configurations

There are many features of `spack` that are only available if you perform the full shell
setup.  Basics such as installing or checking specifications do **not** need this.  So
for example, if you just want to see what was installed in which Spack instance, you
could

```console
$ cd /share/apps/spack

# See what the compilers instance had installed
$ ./spack_compilers/bin/spack find

# See what the all instance had installed
$ ./spack_all/bin/spack find
```

On the other hand, things like loading modules, convenience functions of going to a
failed build's stage, etc, require the full shell integration.  Thankfully it's easy,
just set the `SPACK_ROOT` variable and source a script.  I'll show you an interactive
version, for the `spack_all` instance, but of course you would put this in your
`~/.bash_profile` (only need to source `setup-env.sh` once, so don't do it in the
`~/.bashrc` unless you want every `tmux` pane to source it).

```console
$ export SPACK_ROOT="/share/apps/spack/spack_all"
$ source $SPACK_ROOT/share/spack/setup-env.sh

# Now `spack` is available as a regular old command
# This should give you the same results as the raw
# ./spack_all/bin/spack find above
$ spack find
```

### Convenience Startup Scripts

There are two files you should be sourcing, from your `~/.bashrc` and `~/.bash_profile`
respectively.

#### Bash Profile

Put somewhere in your `~/.bash_profile`:

```bash
# Because ~/.bash* is shared across all systems, make sure you only
# try and load this from totient.
if [[ $(hostname -s) =~ totient ]]; then
    source /share/apps/spack/totient_spack_configs/admin_configs_bash_profile.sh
fi
```

It sets `SPACK_ROOT` to be `/share/apps/spack/spack_all`, and sources `setup-env.sh`.

- As it informs you by sourcing it, this means that `spack` refers to `spack_all`.
- Use `spack_compilers` by `cd /share/apps/spack/spack_compilers` and then execute
  `./bin/spack`.

We don't want to (indirectly) source `setup-env.sh` for every shell (e.g. when using
`tmux`) as the script takes a little bit.

#### Bash RC

Put somewhere in your `~/.bashrc`:

```bash
# Because ~/.bash* is shared across all systems, make sure you only
# try and load this from totient.
if [[ $(hostname -s) =~ totient ]]; then
    source /share/apps/spack/totient_spack_configs/admin_configs_bashrc.sh
fi
```

Functions are treated specially by your shell and need to be defined in the `~/.bashrc`
file.  The functions will **not** be available if you source them from your
`~/.bash_profile`.

1. It defines the convenience function `spack_node_install`, which will launch the job
   script `/share/apps/spack/totient_spack_configs/node_compile.pbs`.  Example usage:

   ```console
   # Make sure it will install what you expect, as well as
   # use dependencies you have compiled.
   $ spack spec -I boost %gcc@7.2.0

   # Launch the job script.
   $ spack_node_install boost %gcc@7.2.0

   # Wait for it to finish
   $ qstat

   # The installation log gets put here
   $ cd $HOME/spack_install_logs

   # I've kept the colors, hence `less -R`
   # Assuming it gave job number 34239
   $ less -R spack_node_install.o34239
   ```

2. It defines the convenience function `update_totient_lmod_db`.  If you are only
   installing things with `spack_node_install` (no compilers), just run it after and the
   module for the package you just installed should now be available.

   - If you were installing for `gcc@7.2.0`, you may need to do

     ```console
     # Load the `gcc/7.2.0` module so that the `spack_all` directory shows up in
     # the $MODULEPATH
     $ module load gcc/7.2.0

     # Now update the database
     $ update_totient_lmod_db
     ```

More on why that's good for you (and ONLY you the admin) to do in the
[Debugging](#debugging) section.

## Syntax

Spack introduces a wide range of syntax and options, this should be enough for you to
simply compile and install packages.

### Commands

The primary commands that you will use:

`spack list`
: Lists all packages available for installing with `spack`.  Best served with a side of
  `grep -i` for what you actually want to install.

`spack info X`
: Pulls up the information on package `X`.  It is **very** important that you look at
  this page before trying to install package `X`, as there may be _variants_ of the
  package that you will want to include that are turned off by default.  See
  command-line syntax in next section for an example.

`spack spec -I X`
: Performs the concretization of what it will take to install package `X` on this
  system.  **ALWAYS ALWAYS ALWAYS** run `spec -I` **before** trying to install package
  `X`.  Let's consider the `boost` package.  It has a variant that allows you to compile
  `boost.python`.  Now suppose that you have also installed `python` using `spack`, but
  you installed `python+tk` (so that you can have `matplotlib`).  **By default, `spack`
  will re-install a `python~tk` and use that as the dependency of `boost`**.

  In short: by running the `spec`, you will be able to determine if the dependency you
  want to use to build something will _actually_ be used.

`spack install X`
: Installs the package!  **Note** that for non-compilers, we will **never** run this
  directly (the job script will do this).  This is so that when the compiler is
  optimizing the code, it is tailored to the compute nodes rather than the login node.

`spack uninstall X`
: Uninstalls the package `X`.  If another package `Y` was built using package `X`,
  `spack` will fail out explaining this.  If you really want to force it, you can
  `spack uninstall --dependents X`.  Exercise extreme caution.

`spack find [package]`
: Allows you to view what you have installed.  The version of this command I use most
  frequently is `spack find -ldfv X`, which provides me with a description of the
  variants package `X` was installed with, what its dependencies were, and most
  importantly the _hashes_ of each.  The hashes also come into play when trying to force
  the concretizer to use something as a dependency.

### Syntax and Examples

The syntax elements we will focus on will be compilers, versions, dependencies, and
variants.  We'll be using `python` and `boost` for example packages, since generally
speaking `python` is actually the hardest part to get right.

**Note**: the syntaxes shown are for use on the command-line (or by argument to the job
script).  This admonition exists to call to your attention that **command-line
specifications take the highest precendence**, superceding any site-specific
configurations present in the various YAML files I have created.  The YAML side is
explained later.

#### Versions

##### Syntax Token: `@`

Every package in Spack has at least one version, and every package in Spack also has a
_preferred version_.  In some cases the preferred version is simply the latest stable
version, in some cases it could be an earlier one due to community preferences and/or
bugs found.  For example, Python's preferred version is `2.7.13`, because even though
it's 2017...(ok I'll spare the rant, it's HPC).  A better example is Boost --- at the
time of writing this, the latest "stable" is `1.64.0`, but the preferred is `1.63.0`.
This is because there are a lot of bugs when `boost+mpi` is desired...

Some examples:

- `spack spec -I python` -> `python@2.7.13` (inherits preferred version)
- `spack spec -I python@3.6.2` gives us 3.6.2.
- `spack spec -I boost@1.64.0`

Simply use `@` followed by the version number.

**Tip**:
: View the versions for package `X` by reading `spack info X`.

#### Compilers

##### Syntax Token: `%`

Spack and `lmod` get along so well because they treat compilers specially.  The general
idea is that if you have two compilers, say `gcc` and `llvm`, you do not want to try and
compile package `X` using `gcc` and build it with a dependency that was compiled with
`llvm`.  ABI compatibility aside, even just two different versions of `gcc` can lead to
difficult bugs.  You can view the compilers available to you with

```console
$ spack compiler list
==> Available compilers
-- gcc rhel6-x86_64 ---------------------------------------------
gcc@7.2.0  gcc@6.4.0  gcc@4.9.2  gcc@4.4.7

-- intel rhel6-x86_64 -------------------------------------------
intel@15.0.3
```

Right now, if you checkout `$SPACK_ROOT/etc/spack/packages.yaml` you will see that at
the bottom the default compiler for `all` packages is `intel`.  So if we do

```console
$ spack spec -I python
Input spec
--------------------------------
     python

Normalized
--------------------------------
     python
         ^bzip2
         ^ncurses
             ^pkg-config
         ^openssl
             ^zlib
         ^readline
         ^sqlite

Concretized
--------------------------------
     python@2.7.13%intel@15.0.3+shared~tk~ucs4 arch=linux-rhel6-x86_64
         ^bzip2@1.0.6%intel@15.0.3+shared arch=linux-rhel6-x86_64
         ^ncurses@6.0%intel@15.0.3~symlinks arch=linux-rhel6-x86_64
             ^pkg-config@0.29.2%intel@15.0.3+internal_glib arch=linux-rhel6-x86_64
         ^openssl@1.0.2k%intel@15.0.3 arch=linux-rhel6-x86_64
             ^zlib@1.2.11%intel@15.0.3+pic+shared arch=linux-rhel6-x86_64
         ^readline@7.0%intel@15.0.3 arch=linux-rhel6-x86_64
         ^sqlite@3.20.0%intel@15.0.3 arch=linux-rhel6-x86_64
```

The `packages.yaml` had some very specific impacts here.  If we instead wanted to do
things with `gcc@7.2.0`:

```console
$ spack spec -I python %gcc@7.2.0
Input spec
--------------------------------
     python%gcc@7.2.0

Normalized
--------------------------------
     python%gcc@7.2.0
         ^bzip2
         ^ncurses
             ^pkg-config
         ^openssl
             ^zlib
         ^readline
         ^sqlite

Concretized
--------------------------------
     python@2.7.13%gcc@7.2.0+shared~tk~ucs4 arch=linux-rhel6-x86_64
         ^bzip2@1.0.6%gcc@7.2.0+shared arch=linux-rhel6-x86_64
         ^ncurses@6.0%gcc@7.2.0~symlinks arch=linux-rhel6-x86_64
             ^pkg-config@0.29.2%gcc@7.2.0+internal_glib arch=linux-rhel6-x86_64
         ^openssl@1.0.2k%gcc@7.2.0 arch=linux-rhel6-x86_64
             ^zlib@1.2.11%gcc@7.2.0+pic+shared arch=linux-rhel6-x86_64
         ^readline@7.0%gcc@7.2.0 arch=linux-rhel6-x86_64
         ^sqlite@3.20.0%gcc@7.2.0 arch=linux-rhel6-x86_64
```

**Note**:
: We see here that Spack will want to use the same compiler for every dependency.  This
  cannot be changed (nor should it be).

**Tip**:
: You can just do `%intel`, for example, if it's the only one.  Generally, you just need
  to provide Spack with _enough_ information for it to complete.  It's very smart.

#### Variants

##### Syntax Tokens: `+variant` to add, `~variant` to remove

Variants typically are just what components of a package you want to build.  In the
Python case, the variant that defaults to off is `tk`, since Spack is generally designed
for clusters which typically don't have graphical logins.  If you take a closer look at
the output of the previous `%gcc@7.2.0` output, you'll see that Python defaulted to be
`python+shared~tk~ucs4`:

- Build shared libs
- Do not build with `tk`
- Do not build with (wide) unicode strings

If we on the other hand wanted to install it with `tk`:

```console
$ spack spec -I python+tk
Input spec
--------------------------------
     python+tk

Normalized
--------------------------------
     python+tk
         ^bzip2
         ^ncurses
             ^pkg-config@0.9.0:
         ^openssl
             ^zlib
         ^readline
         ^sqlite
         ^tcl
         ^tk
             ^libx11
                 ^inputproto
                     ^util-macros
                 ^kbproto
                 ^libxcb@1.1.92:
                     ^libpthread-stubs
                     ^libxau@0.99.2:
                         ^xproto@7.0.17:
                     ^libxdmcp
                     ^xcb-proto
                 ^xextproto
                 ^xtrans

Concretized
--------------------------------
     python@2.7.13%intel@15.0.3+shared+tk~ucs4 arch=linux-rhel6-x86_64
         ^bzip2@1.0.6%intel@15.0.3+shared arch=linux-rhel6-x86_64
         ^ncurses@6.0%intel@15.0.3~symlinks arch=linux-rhel6-x86_64
             ^pkg-config@0.29.2%intel@15.0.3+internal_glib arch=linux-rhel6-x86_64
         ^openssl@1.0.2k%intel@15.0.3 arch=linux-rhel6-x86_64
             ^zlib@1.2.11%intel@15.0.3+pic+shared arch=linux-rhel6-x86_64
         ^readline@7.0%intel@15.0.3 arch=linux-rhel6-x86_64
         ^sqlite@3.20.0%intel@15.0.3 arch=linux-rhel6-x86_64
         ^tcl@8.6.6%intel@15.0.3 arch=linux-rhel6-x86_64
         ^tk@8.6.6%intel@15.0.3 arch=linux-rhel6-x86_64
             ^libx11@1.6.5%intel@15.0.3 arch=linux-rhel6-x86_64
                 ^inputproto@2.3.2%intel@15.0.3 arch=linux-rhel6-x86_64
                     ^util-macros@1.19.1%intel@15.0.3 arch=linux-rhel6-x86_64
                 ^kbproto@1.0.7%intel@15.0.3 arch=linux-rhel6-x86_64
                 ^libxcb@1.12%intel@15.0.3 arch=linux-rhel6-x86_64
                     ^libpthread-stubs@0.4%intel@15.0.3 arch=linux-rhel6-x86_64
                     ^libxau@1.0.8%intel@15.0.3 arch=linux-rhel6-x86_64
                         ^xproto@7.0.31%intel@15.0.3 arch=linux-rhel6-x86_64
                     ^libxdmcp@1.1.2%intel@15.0.3 arch=linux-rhel6-x86_64
                     ^xcb-proto@1.12%intel@15.0.3 arch=linux-rhel6-x86_64
                 ^xextproto@7.3.0%intel@15.0.3 arch=linux-rhel6-x86_64
                 ^xtrans@1.3.5%intel@15.0.3 arch=linux-rhel6-x86_64
```

Of course, we can still use `gcc` if we want.  I won't include the output, but the
command would be

```console
$ spack spec -I python %gcc@7.2.0 +tk
```

#### Dependencies

##### Syntax Token: `^`

The reason you should **always** check `spack spec -I X` is because the package defaults
may be more relaxed, and Spack will install the relaxed version.  Boost is an excellent
test case to see what happens.

Basically, if you check `spack spec -I boost` you will see that it picks up the
`python@2.7.13` already compiled.  In order for you to compile `boost.python` with
`python@3.6.0`, you have to do something really obscene.  Traditionally, you should be
able to do `spack spec -I boost ^python@3.6.1`, but there is a known concretizer bug
and it will simply say "Boost does not depend on Python".  Even though our `packages.yaml`
is specifically asking for `+python`, this basically gets discarded.

So to actually install it, say for `gcc@7.2.0`, copy-paste the variants from the
`packages.yaml` and _then_ incorporate `^python@3.6.1`:

```bash
# woah
$ spack spec -I boost +atomic+chrono+date_time+filesystem+graph+iostreams+locale+log+math+mpi+multithreaded+program_options+python+random+regex+serialization+shared+signals+system+test+thread+timer+wave %gcc@7.2.0 ^python@3.6.1
```

It's also worth mentioning that you can specify the "hash" explicitly.  This will not
solve the needing-to-paste-the-full-variants-list problem, but can be helpful if you are
trying to say force `boost` as a dependency and don't want to type all that.  Keeping
with the above example, where we wanted to use `%gcc@7.2.0 ^python@3.6.1`, you can use

```console
$ spack find -ldfv python
-- linux-rhel6-x86_64 / gcc@7.2.0 -------------------------------
55rmf7o    python@2.7.13%gcc+shared~tk~ucs4
vbjrkfg        ^bzip2@1.0.6%gcc+shared
vpld45l        ^ncurses@6.0%gcc~symlinks
ljl2c6v        ^openssl@1.0.2k%gcc
52qgokm            ^zlib@1.2.11%gcc+pic+shared
tnmwqjt        ^readline@7.0%gcc
srs4rn5        ^sqlite@3.20.0%gcc

mmc4fw7    python@3.6.1%gcc+shared~tk~ucs4
vbjrkfg        ^bzip2@1.0.6%gcc+shared
vpld45l        ^ncurses@6.0%gcc~symlinks
ljl2c6v        ^openssl@1.0.2k%gcc
52qgokm            ^zlib@1.2.11%gcc+pic+shared
tnmwqjt        ^readline@7.0%gcc
srs4rn5        ^sqlite@3.20.0%gcc
```

So instead of using `^python@3.6.1`, we could also use `^/mmc4fw7`.

**Note**:
: The syntax for specifying a hash in `spack` is `/<hash>` with the `/` character being
  the thing that tells `spack` "this is a hash".  This is true for all commands, not
  just checking `spec -I` or `install`.

One final note about dependencies is that you may end up in situations where if you try
and specify the dependencies manually, the concretizer will say "cannot depend on X
twice."  This is a frustrating situation to be in, and usually involves being clever.
Do they have a common dependency that you can specify instead?  Usually, if you ended up
in this scenario, they do.  Happy hunting.

# Totient and Spack
----------------------------------------------------------------------------------------

Since compiling the compilers is something we only want to do once (if possible), the
approach suggested in the Spack docs of keeping a separate `spack` instance was
employed.  The directory structure:

```
/share/apps/spack/
├── spack_all
├── spack_compilers
├── totient_spack_configs
└── zzz_install_logs
```

**spack_all**
: The `spack_all` directory is where all non-compilers are installed, except for `lmod`
  and `tmux`.

**spack_compilers**
: The `spack_compilers` directory is where all compilers are installed.  The `lmod` and
  `tmux` packages have also been installed here as we want to ensure these packages
  remain available regardless of what happens with `spack_all`.

  **Note**: all compilers were compiled using `gcc@4.9.2` provided by the RHEL
  `devtoolset/3` package.  Traditionally you would use the host compiler, but
  `gcc@4.4.7` (at least as installed on Totient) is insufficient, lacking `libatomic`.

  This is particularly relevant for the configurations of each `spack` instance
  described next.

**totient_spack_configs**
: See [Totient Specific Spack Configurations](#totient-specific-spack-configurations).

**zzz_install_logs**
: Where I put all of the completed job script outputs for reference.  Not very well
  organized.

**Note**:
: SpackMan explained to me that although the official docs describe this approach, he
  and the majority of the other leads _strongly_ disagree with this tactic.  Amusingly,
  the proponent of this tactic is somebody I generally disagree with.

  In this instance, though, I wholeheartedly agree with the approach.  Why?  It means
  that you can `./spack_all/bin/spack uninstall -a` and completely start from scratch
  if you want, **without** having to worry about obliterating the compilers.

## EXTREME CAUTION IS REQUIRED

It can be very easy to perform actions that can leave Spack in a confused, conflicted,
and ultimately broken state.  Because we are `qsub`bing jobs for compiling things, you
need to be **EXCEPTIONALLY CAREFUL** about doing this blindly.

Consider wanting to compile `python@2.7.13` and `python@3.6.2`.  If you check the specs,
you will see that they pretty much share all of the same dependencies.  The only thing
that differs really is downloading a different Python source tarball and compiling it.
If you `qsub` a job to compile `python@2.7.13` and `python@3.6.2` at the same time, and
none of the dependencies have been compiled yet, you just made what I will call a
_compilation race condition_.  Spack may be able to notice this, it may not.
Heisenbugs, blood, and tears.

**Solution**:
: Do not ever try and compile something that will need to compile the same dependency
  at the same time.  **ALWAYS** check `spack spec -I`.

## Totient Specific Spack Configurations

If you look in the `/share/spack/totient_spack_configs/setup/spack_yaml` folder, you
will find the various configurations.  There are two things worth explicitly noting:

1. When you try and build `llvm`, you'll likely need to change the `config.yaml` and
   un-comment the part that changes where the `stage` goes (so that you have enough
   space to actually compile it, because its HUGE).

2. The `all_packages.yaml` gets symlinked into `spack_all`, and `cc_packages.yaml` into
   `spack_compilers`.  Though separating the spack instances makes things cumbersome
   when the `lmod` stuff comes into play, this alone is worth it.  We want to compile
   everything with the `gcc@4.9.2` in `spack_compilers`.

The `config.yaml`, `modules.yaml`, and `compilers.yaml` get symlinked into both.

See the `create_and_verify_links.sh` script.

### Considerations for Modules

The `modules.yaml` file is what controls how module files are generated, and which ones
are excluded.  You may decide that you want to split them into an `all_modules.yaml`
and a `cc_modules.yaml`.

After making changes to `modules.yaml`, e.g. to add more things to the blacklist so as
not to confuse students, you should follow the directions in the
[Spack Module Setup](#spack-module-setup) section.

# Totient and Spack and Lmod
----------------------------------------------------------------------------------------

The setup for `lmod` is a little convoluted, it was setup this way partially to support
custom configurations, and partly because this is what worked.  AKA I make no claims as
to this being the officially correct way to configure it all, but it at least works.

## Brief Overview of Lmod

Lmod operates hierarchically:

1. First, a user is expected to `module load some_compiler`
2. Only after a specific compiler module has been loaded will modules compiled with that
   compiler be available.
3. The next layer is for MPI implementation used.  In general I do not think this
   applies directly to Totient, because we only have OpenMPI or Intel's MPI (?).  But if
   different MPI implementations are used the future, that becomes relevant.

You can enable deeper hierarchies, e.g. for LAPACK.  This feature seems to still be in
development, and was not employed on the Totient configurations.  See  the Spack
documentation on [extended hierarchies][spack_lmod_ext].

## Links Used in Getting Lmod Setup

- [Official Lmod Documentation][lmod]
    - [Lmod User Guide][lmod_user_guide]
    - Writing and converting Modulefiles
        - [Lmod Tutorial on Writing Modulefiles][lmod_writing_tutorial]
        - [Converting TCL to Lua][lmod_tcl_to_lua]
    - Site specific customizations
        - [Lmod Customization Using `lmodrc.lua`][lmod_lmodrc]
            - Link broken?  Search in google

               ```
               cache:http://lmod.readthedocs.io/en/latest/155_lmodrc.html
               ```

            - [Related Discussion on Shared Filesystems][lmod_shared]
        - [Assigning Properties to Modules][lmod_properties]
        - [Loading Default Modulefiles for all Users][lmod_defaults]
    - Setting up the `lmod` spider cache
        - [Lmod Cache (Re)generation][lmod_cache]
- [Spack and Modules Documenation][spack_modules]
    - [Spack and Lmod][spack_lmod]
    - Related issues that helped create the Totient Setup
        - [TACC/lmod discussion][tacc_lmod_issue]
        - [Spack/lmod, core compilers, and spack][spack_lmod_issue]
        - [Spack/lmod walkthrough][spack_lmod_help]

[lmod]:                  http://lmod.readthedocs.io/en/latest/index.html
[lmod_user_guide]:       http://lmod.readthedocs.io/en/latest/010_user.html
[lmod_tcl_to_lua]:       http://lmod.readthedocs.io/en/latest/095_tcl2lua.html
[lmod_writing_tutorial]: http://lmod.readthedocs.io/en/latest/015_writing_modules.html
[lmod_lmodrc]:           http://lmod.readthedocs.io/en/latest/155_lmodrc.html#lmodrc-label
[lmod_shared]:           http://lmod.readthedocs.io/en/latest/120_shared_home_directories.html
[lmod_properties]:       http://lmod.readthedocs.io/en/latest/015_writing_modules.html#assigning-properties
[lmod_defaults]:         http://lmod.readthedocs.io/en/latest/070_standard_modules.html
[lmod_cache]:            http://lmod.readthedocs.io/en/latest/130_spider_cache.html#how-to-test-the-spider-cache-generation-and-usage

[spack_lmod_ext]:   http://spack.readthedocs.io/en/latest/tutorial_modules.html#extend-the-hierarchy-to-other-virtual-providers
[spack_modules]:    http://spack.readthedocs.io/en/latest/module_file_support.html#configuration-in-modules-yaml
[spack_lmod]:       http://spack.readthedocs.io/en/latest/tutorial_modules.html#lua-hierarchical-module-files
[tacc_lmod_issue]:  https://github.com/TACC/Lmod/issues/245
[spack_lmod_issue]: https://github.com/LLNL/spack/issues/3973
[spack_lmod_help]:  https://github.com/LLNL/spack/issues/4666

## Totient Lmod Startup and Configurations

The Lmod startup and configurations are paired: first the "traditional" Lmod startup
files are used (as described in the [Lmod Installation Guide][lmod_install]).  We then
add another startup script that configures the important aspects of Totient's module
system.

[lmod_install]: http://lmod.readthedocs.io/en/latest/030_installing.html#installing-lmod

### Lmod on Startup

In order for every user to have access to Lmod, the following links must be created
(you will need to submit a ticket to IT since we don't have `root`):

1. The standard Lmod startup files, which enable the `module` command for users.

    ```console
    # This works for bourne shells and zsh
    $ ln -s /share/apps/spack/totient_spack_configs/setup/login/z00_lmod.sh /etc/profile.d/z00_lmod.sh
    # For csh and tsch users
    $ ln -s /share/apps/spack/totient_spack_configs/setup/login/z00_lmod.csh /etc/profile.d/z00_lmod.csh
    ```

   The files `/share/apps/spack/totient_spack_configs/setup/login/z00_lmod.[c]sh` are in
   turn links to the actual `lmod` installation files.  This enables you to, if you so
   desire, re-install `lmod` and change where these point to.

2. Now that the Lmod startup files have been linked, we need to link the site-specific
   startup files:

    ```console
    # This is for the bourne shells and zsh
    $ ln -s /share/apps/spack/totient_spack_configs/setup/login/z01_lmod_Totient.sh /etc/profile.d/z01_lmod_Totient.sh
    # For csh and tsch users
    $ ln -s /share/apps/spack/totient_spack_configs/setup/login/z01_lmod_Totient.csh /etc/profile.d/z01_lmod_Totient.csh
    ```

**Warning**:
: The naming of the files is important!  The `z00` files provide the `module` command,
  which is then directly used in the `z01` files.  Since files in `/etc/profile.d` are
  sourced using a glob (`*.sh in /etc/profile.d` for bourne shells, `*.csh` for `tsch`
  and `csh`), files get sourced in alphabetical order.  `z00` will get sourced before
  `z01`.

### Lmod Configurations

The `z01` files are the first form of site-specific customization.  Let's take a look at
the `.sh` file:

```bash
# Disable the system modules from showing up (hack)
# Links to both spack instances
TOTIENT_SPACK_ROOT="/share/apps/spack"
CC_ROOT="$TOTIENT_SPACK_ROOT/spack_compilers"
CORE="share/spack/lmod/linux-rhel6-x86_64/Core"
CC_CORE="$CC_ROOT/$CORE"

# Links to the default Totient, psxe/2015, and devtoolset/3
TOTIENT_MODULES_PREFIX="$TOTIENT_SPACK_ROOT/totient_spack_configs/modules"
TOTIENT_CORE="$TOTIENT_MODULES_PREFIX/lmod/Core"

export MODULEPATH="$TOTIENT_CORE:$CC_CORE"
export LMOD_RC="$TOTIENT_SPACK_ROOT/totient_spack_configs/setup/lmod/lmodrc.lua"

# See documentation:
# http://lmod.readthedocs.io/en/latest/070_standard_modules.html

if [ -z "$__Init_Default_Modules" ]; then
   export __Init_Default_Modules=1;

   ## ability to predefine elsewhere the default list
   LMOD_SYSTEM_DEFAULT_MODULES=${LMOD_SYSTEM_DEFAULT_MODULES:-"Totient"}
   export LMOD_SYSTEM_DEFAULT_MODULES
   module --initial_load --no_redirect restore
else
   module refresh
fi
```

Recalling that we have **two** separate Spack instances, this part is important.  We are
explicitly overriding any system populated `MODULEPATH` and setting it to instead be

- `/share/apps/spack/totient_spack_configs/modules`
- `/share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core`

#### The `Totient` Login Module

The default module `/share/apps/spack/totient_spack_configs/Core/Totient.lua` is what
gets loaded by default for every user, because we set this explicitly in the `z01` files
being sourced.  Edit the file to load in whatever specific modules you would like!

#### Relating `spack_all` and `spack_compilers`

We have deliberately excluded the `spack_all` module path from being included in the
`MODULEPATH` of the users.  This is the one tricky part of the setup that has the
capability of being broken (fix described in next section).  Remember that crazy script
`create_and_verify_links.sh`?  The very bottom of the script is the relevant section
here:

```bash
###############################################################################
# Try and automate the spack_compiler -> spack_all lmod hacks                 #
###############################################################################
vsep "Attempting 'spack_compiler' -> 'spack_all' patches READ THE OUTPUT"
the_patches=( gcc/6.4.0.patch gcc/7.2.0.patch )
p_dir="$HERE/patches/spack_modules"

for patch in "${the_patches[@]}"; do
    echo '*** Executing: patch -d / -N -p 1 --reject-file="-" -i "'"$p_dir/$patch"'"'
    patch -d / -N -p 1 --reject-file="-" -i "$p_dir/$patch"
    echo -e "\n\n"
done
```

Let's take a look at the patch
`/share/apps/spack/totient_spack_configs/setup/patches/spack_modules/gcc/6.4.0.patch`:

```diff
--- a/share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core/gcc/6.4.0.lua
+++ b/share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core/gcc/6.4.0.lua
@@ -11,7 +11,7 @@ family("compiler")

 -- MODULEPATH modifications

-prepend_path("MODULEPATH", "/share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/gcc/6.4.0")
+prepend_path("MODULEPATH", "/share/apps/spack/spack_all/share/spack/lmod/linux-rhel6-x86_64/gcc/6.4.0")

 -- END MODULEPATH modifications
```

We have to tell `spack_compilers` modules to look in the `spack_all` directory.  This
must be done for **every** compiler you get setup.  SpackMan told me they plan on
rewriting the module generation stuff, so these patches may become stale and need to be
re-written.

## Spack Module Setup

So let's say that you've got a new core module you want to load automatically for the
students.  In this case, I just installed a newer copy of `vim`.  Recall that core
utilities such as compilers, `tmux`, `vim`, etc are compiled using `spack_compilers`.

So I've just gone through and successfully compiled
`./spack_compilers/bin/spack install vim`, but right now there is no `vim` module
generated underneath `spack_compilers/share/spack/lmod/Core`.  This is because of our
`modules.yaml` file.  The relevant excerpts:

```yaml
modules:
    enable::
        - lmod
    lmod:
        core_compilers:
            - 'gcc@4.9.2'
        hash_length: 0
        whitelist:
            - cmake
            - curl
            - gcc
            - git
            # NOTE: DO NOT PUT `lmod` HERE! It comes from login/z01_Totient.[c]sh
            - lua
            - tmux
        blacklist:
            # NOTE: spack generated module file infinite recursion.
            #       made custom module file
            - intel-parallel-studio
            - '%gcc@4.9.2'
```

I need to add `vim` to the **whitelist**, since the `spack_compilers` instance is setup
(via it's `packages.yaml`) to always use `gcc@4.9.2` from `devtoolset/3`.  Because we
specifically added `%gcc@4.9.2` to the **blacklist**, this says "blacklist anything that
is not explicitly in the whitelist, and was compiled with `gcc@4.9.2`."  This is overall
very desireable, since we don't want all of the dependencies of the compilers to show
up for students (because it's a lot, and would be very confusing).

So now I've added `vim` to the **whitelist**, but we've already installed it!
Thankfully Spack is very lenient on this, you can regenerate all of the modules.

```console
# Go to `spack_compilers`
$ cd /share/apps/spack/spack_compilers
# Regenerate the modules
$ ./bin/spack module refresh --module-type lmod --delete-tree -y
==> Regenerating lmod module files
```

The `vim` module file is now generated, but **is not available yet**.  Before we try and
make it available, though, we need to re-patch the modulefiles to point to `spack_all`.

```console
# Go to the configs setup directory
$ cd /share/apps/spack/totient_spack_configs/setup

# Execute the linkage script, which patches at the end
# Only including relevant patch output
$ ./create_and_verify_links.sh
...
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>> Attempting 'spack_compiler' -> 'spack_all' patches READ THE OUTPUT
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*** Executing: patch -d / -N -p 1 --reject-file="-" -i "/share/apps/spack/totient_spack_configs/setup/patches/spack_modules/gcc/6.4.0.patch"
patching file share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core/gcc/6.4.0.lua



*** Executing: patch -d / -N -p 1 --reject-file="-" -i "/share/apps/spack/totient_spack_configs/setup/patches/spack_modules/gcc/7.2.0.patch"
patching file share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core/gcc/7.2.0.lua
```

## Regenerating the Spider Cache

In the previous section I showed you what has to happen when you want to make a new
compiler or default core utility when installed with `spack_compilers`.  After making
sure to re-patch the `spack_compilers` compiler modules so that they point to what is
compiled with `spack_all`, we need to update the spider cache.  Assuming you've followed
the directions in the [Admin Shell Configuations](#admin-shell-configurations) section,
you should have the `update_totient_lmod_db` function avaiable to you.

In the below output, `vim` will show up in the top-right after we run the update.

```console
$ module av

 /share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core
   cmake/3.9.0 (L)    gcc/7.2.0  (D)    tmux/2.4 (L)
   curl/7.54.0 (L)    git/2.13.0 (L)
   gcc/6.4.0          lua/5.3.4  (L)

---- /share/apps/spack/totient_spack_configs/modules/lmod/Core -----
   Totient      (I,L)    devtoolset/3 (I)    psxe/2015 (I)
   TotientAdmin (I)      intel/15.0.3

  Where:
   L:  Module is loaded
   I:  Ignore - not intended for direct use.
   D:  Default Module

Use "module spider" to find all possible modules.
Use "module keyword key1 key2 ..." to search for all possible
modules matching any of the "keys".

$ update_totient_lmod_db
---> Loading the 'TotientAdmin' module.
---> Running 'update_lmod_system_cache_files', this may take a while...
---> Unloading the 'TotientAdmin' module.

$ module av

 /share/apps/spack/spack_compilers/share/spack/lmod/linux-rhel6-x86_64/Core
   cmake/3.9.0 (L)    gcc/7.2.0  (D)    tmux/2.4     (L)
   curl/7.54.0 (L)    git/2.13.0 (L)    vim/8.0.0503
   gcc/6.4.0          lua/5.3.4  (L)

---- /share/apps/spack/totient_spack_configs/modules/lmod/Core -----
   Totient      (I,L)    devtoolset/3 (I)    psxe/2015 (I)
   TotientAdmin (I)      intel/15.0.3

  Where:
   L:  Module is loaded
   I:  Ignore - not intended for direct use.
   D:  Default Module

Use "module spider" to find all possible modules.
Use "module keyword key1 key2 ..." to search for all possible
modules matching any of the "keys".
```

**Tip**:
: You only have to re-patch things when installing into `spack_compilers`.  When using
  `spack_all` (e.g. via `spack_node_install`), simply re-update the database.

**Note**:
: In the above example we went through start-to-finish how to get a default module from
  install to show up in the `lmod` setup.  The last step would be, if you want it to be
  loaded on login for everybody, add it to `Totient.lua`.


# Debugging
----------------------------------------------------------------------------------------

While I wish you could just ignore this section, I'm sure you'll end up here.  In the
customized `config.yaml` section, we had explicitly moved the Spack staging area away
from `/tmp`.  This is where having the shell integrations becomes particularly useful.

Suppose we were trying to compile `python` and things didn't work out.  There are two
things that come out immediately:

1. Check the output on the job script.  Assuming you were using my wrapper, it should
   have ended up in `/home/$USER/spack_install_logs`.  Sometimes the error was easy for
   Spack to discern, and it will tell you what went wrong.

   - For example, you ran out of space and it gave you an `IOException: Out of Disk Space`.

2. The staging area is in-tact still!  In the staging area, there are two files that are
   very useful in figuring out what went wrong:

   - `spack-build.out`: this is the full output of the build, from `./configure` to
     `make` and beyond.  For example, this is the file where the `ld killed with signal
     9` error was shown when trying to compile `llvm` without enough RAM / swap space
     on the login node.

   - `spack-build.env`: this file provides a full dump of the build environment that was
     used to compile this package.  If you failed on trying to link against something
     that showed up in your personal `$LD_LIBRARY_PATH`, chances are it wasn't in this
     file.  This is because Spack aims to sanitize any and all aspects of the build
     environment it can.

Generally speaking the `spack-build.out` file is you want to look at, but it's good to
know about the `spack-build.env` as well.

## How to Proceed

The easiest thing you can try is to turn off variants for the package you are trying
to install.  `spack info X` and see what dials you can turn.  Many packages build
out-of-the-box, but a few choice packages are always troublesome.

**Example**:
: When using Fedora, I was never able to get `gcc+binutils` to build.  It used to
  default to `+binutils`, but so many other users encountered this issue that they
  switched it to `~binutils` as the default.

  Interestingly, I could _only_ get `gcc+binutils` to compile on Totient!

## The Builtin Knobs Will Not Turn

If you really do need a specific variant, or turning them on / off does not work, this
is where making sure you have the shell integrations described in the
[Admin Shell Configuations](#admin-shell-configurations) section becomes very helpful.

`spack cd X`
: Go to the staging directory for package `X`.  This only remains available when you
  actually have a failed build, or have explicitly run `spack stage X`.  AKA if the
  installation was successful, `spack cd X` does not work.

Example:

```console
sjm324@en-cs-totient-01:~> spack cd python@3.6.1
sjm324@en-cs-totient-01:/share/apps/spack/spack_all/var/spack/stage/python-3.6.1-664mnn7
vb6ta6q6pusoupoepeumbftod/Python-3.6.1> less spack-build.out
```

Or just remember that `spack_all/var/spack/stage` is where they are.  Now do some
digging and try and figure out what went wrong.

### Check the Debug Log

In the `/share/apps/spack/totient_spack_configs/node_compile.pbs` script, there is a
line commented out that uses `/share/apps/spack/spack_all/bin/spack -d install ...`.
Switch that on and comment out the other one.  The `spack -d` mode will include a lot
more information about what went wrong where.

### Try Compiling Manually

Because you can.  **However**, recall that Spack has installed all of our dependencies.
So when you check `spack spec -I X` (I'm assuming `X` actually failed, not its
dependencies), when trying to compile manually you will want to `spack load Y` to load
the dependency `Y`.  This way you can try and replicate what Spack will do.  Then maybe
if it is a package like a compression library or something, `spack unload Y` and see if
it compiles now?

### Modify the Spack Package

Maybe you tried compiling manually, maybe not.  Another useful feature to know about is
that Spack can load up the file directly.  You can `spack edit X` to bust that out and
read the source code.  Maybe there is a `TODO:` in there that affects you!

**Pro-Tip**:
: Make sure you have the `EDITOR` environment variable set to what you want, this is
  what Spack will open up the file in.

**DANGER ZONE**:
: YOU ARE NOW EDITING SPACK DIRECTLY.  I mean look I'm a hacker and I do that all the
  time.  But the more you change, the more confusing things can get.  It's very easy to
  change package `Y` trying to fix something, then change `Z`, then forget to un-change
  `Y` and be even more broken.

  This is also why `spack_all` and `spack_compilers` was created.  So that you truly can
  obliterate and restart :)

# Factory Reset
----------------------------------------------------------------------------------------

The `spack_all` instance is **NOT** on the `develop` branch, because the 2015 Intel
compiler has a different directory structure than what SpackMan had access to.

## Soft Reset

Try this first, so that you don't have to recreate my nonsense.

```console
$ cd /share/apps/spack/spack_all
# DANGER: uninstalls it ALL
$ ./bin/spack uninstall -a

# You should be on `old_intel_compilers`, which has two commits
$ git branch
# If you were editing files and don't know what you did
$ git status
# Or whatever.  You know what you did.
$ git reset --hard
```

## Hard Reset

So if you straight up `rm -rf spack_all`, you will want to

1. Fresh clone, go back in time (Spack updates a lot).

   ```console
   $ cd /share/apps/spack
   $ git clone https://github.com/LLNL/spack.git spack_all
   $ cd spack_all
   # This is the commit on develop I diverged from
   $ git checkout 99fb394ac18b7ef1bc4f9ee34242a69b42781ab8
   ```

2. Checkout a new branch and apply the patch

   ```console
   $ git checkout -b old_intel_compilers
   $ git apply /share/apps/spack/totient_spack_configs/setup/patches/intel_2015.patch
   ```

If you apply the patch to a newer version of `develop`, it may be more broken than not.

# Future TODO

- GET IT TO FIX THE SYMLINKS.  I replied-all to the e-mail.
- BUILD LLVM (in same ticket, requested more swap).
- FIX THE PERMISSIONS.
    - **REMOVE WRITE PERMISSIONS FOR OTHER**.  Get the `totient-admin` group setup.
- Right now, the `intel` compiler is generally broken.  It could work with some things,
  but MPI is mostly broken.
    - Proposed course of action: convert the existing module files into `lmod` modules
      following the [TCL to Lua][lmod_tcl_to_lua] tutorial.  This is how the existing
      `psxe/2015` and `devtoolset/3` modules in
      `/share/apps/spack/totient_spack_configs/modules/lmod/Core` were created, and seem
      to work exactly as expected.
    - Modify the existing `totient_spack_configs/modules/lmod/Core/intel/15.0.3.lua` to
      prepend wherever you decide to put these converted module files.
    - For reference, you can `spack find %intel` to see what was able to be compiled.
        - As we discussed, anything that had `+mpi` may be completely broken.
    - If you want to ditch all of it: `spack uninstall -a %intel`.
- Python and decisions.
    - You have two options: either use `module load` for python packages, or use
      `spack activate`.  I always use `activate`, which makes a symlink into the
      `site-packages` directory.
    - Things that build with python (e.g. the `boost` and `opencv` for both gcc) can
      also be activated.  Maybe not `boost`, I forget.
    - Currently, because of what is in `modules.yaml`, the modules at least get a
      `py2` or `py3` suffix.  But I think `activate` and then blacklisting the modules
      may be the least confusing.
    - Please understand, you currently have **6** python installations.  2.7.13 and
      3.6.1 for `intel`, `gcc@7.2.0`, and `gcc@6.4.0`.  I only used spack to install the
      important AKA need true backend python libraries.  Basically, numpy, scipy and pandas.
    - I did this fully for both `gcc`, `intel` failed.
    - I also installed `pip` for the `gcc` libraries.  If you want another package, first
      check `spack list | grep -i py-THING`.  If it's there, use `spack` and `activate`
      (if that was your decision).  Otherwise, making sure `which pip` points where it
      should (e.g. via `activate` and `module load gcc@7.2.0` then `module load python/2.7.13`)
      (since `activate` creates symlinks).

## Future TODO Notes

1. If I could do it again, I'd call them `spack_core` and `spack_all`.  The
   `spack_compilers` one ended up with a lot more "core" stuffs.
2. If you upgrade to Intel 2017, maybe try and get `spack_compilers` to install it and
   then mark it as `buildable: False` in `all_packages.yaml`, the path is just wherever
   `spack` installed it to under `spack_compilers/opt/spack/...`.

   - The reports online seem to indicate that `spack` works will with 2017.

Unclear how MODULEPATH is actually getting set.

- wassup with `/etc/auto.share` ?
    - `/etc/exports` ?


`spack module refresh --module-type lmod --delete-tree -y`


