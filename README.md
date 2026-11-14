# vee

A small command-line weblog and Gopher phlog publisher, written in portable
shell. Write in your editor or pipe text in; keep your posts as ordinary files.
No database, application server, or mandatory configuration.

## Quick start

Install into your own account, without root access:

```sh
curl -fsSL https://github.com/oodler577/vee/releases/download/v2.0/install.sh -o install.sh
sh install.sh
```

The default destination is `~/.local/bin`. The installer prints the PATH setting
if needed. From a checkout, simply run `sh install.sh`; use `--prefix "$HOME"`
for `~/bin`, or another writable prefix. See INSTALL for details. Then run vee
in your publication directory:

```sh
vee -t 'First post'
printf 'Hello from the command line.\n' | vee -b -t 'Another post'
vee -G -t 'A Gopher post'
vee -g -t 'Publish to both'
```

HTML is indexed in `vee.html`. Raw posts and generated post files live in `.vee/`.
Gopher mode creates `gophermap` and a `phlogsrc` symlink. Your web or Gopher server
serves these files; vee does not run a server.

The default formatter uses groff when available, otherwise fmt (or fold on minimal systems without fmt). Select `-f none`
for literal text, `-f fmt` or `-f fold` for wrapping, or `-f groff` explicitly.
Literal text mode preserves the historical ability to include HTML in web posts;
post bodies are **not** automatically HTML-escaped. Titles in generated HTML are
escaped. Write only content you intend to publish.

## Uninstall

```sh
curl -fsSL https://github.com/oodler577/vee/releases/download/v2.0/uninstall.sh -o uninstall.sh
sh uninstall.sh --dry-run
sh uninstall.sh
```

Use the same `--prefix` as installation if you chose a custom location. This
removes the six installed commands; blogs, configuration, shell startup files,
and other commands remain in place. No root access, Git, or Perl is required.

## Everyday commands

```sh
vee -n                         # List newest first
vee -o                         # List oldest first
vee -l                         # Edit and regenerate the latest post
vee -L 3                       # Edit and regenerate the third latest post
vee -r 3                       # Regenerate the third latest post
vee -R                         # Regenerate all posts
vee -R -g                      # Regenerate HTML and Gopher output
vee -d /path/to/blog -n         # Work in another publication directory
vee -h                         # Full option help
```

Use `-I` for `index.html`, or `-i filename` for another index. Use the same mode
and index settings for later operations, or put them in a local `.veerc`.
Command-line options take precedence over config. Config files, custom
formatters, and hooks are trusted shell code.

A message passed with `-m` is followed by standard input in batch mode. Batch
mode reads until EOF; for message-only batch jobs, redirect from `/dev/null`.
Piped input preserves backslashes, blank lines, and an unterminated final line.
Titles must fit on one line and cannot contain tabs.

## Configuration and extensions

Copy `dot.veerc` to `.veerc` in the publication directory and edit the settings
you need. `gopher-only.veerc` is another starting point. No config file is needed
for normal use. `EDITOR` selects your editor, defaulting to `vi`.

HTML templates are `vee-top.tpl` and `vee-bottom.tpl`; override with `-T` and `-B`.
The executable hooks `vee-pre` and `vee-post` receive `html` or `gopher` as `$1`.
A hook's nonzero exit status stops the operation. Hooks should avoid modifying
source posts. Custom formatter functions can be sourced from `vee-custom.sh`;
see `custom-formatters/` for examples. Formatter output is staged before replacing
a published post; custom formatters must write to the supplied `FINAL`/`gFINAL`.

`veels`, `veefind`, and `veecat` provide post listing and metadata/body extraction.
For example:

```sh
veels | veecat -t
veels | veecat -b
vee-rebuild > recovered-index.html
```

`vee-rebuild` reconstructs a basic HTML index from raw metadata. It does not
recover manually added index markup or summaries. Inspect the recovered file
before replacing your current index.

`vee-publish` is an optional rsync/SSH helper. It reads `DIR` (the publication
root) from `~/.veerc` and accepts `-s user@host:path`. Unlike the blog-local config,
this config belongs to the publishing helper. It includes `.vee/` in uploads;
raw source files are part of vee's public output. Review the destination before
running it. rsync and SSH are optional dependencies of this helper only.

## Preservation and deletion

Existing raw post filenames and the six-line metadata header remain supported.
Back up the publication directory before upgrading or doing bulk edits.

To delete posts, remove their links from the selected HTML index (or the Gopher
map in `-G` mode), inspect `vee -p`, then run `vee -P`. Supply the same index and
mode options to both commands. Purge removes only the known raw, HTML, and Gopher
files for each orphan; unrelated suffixes are retained.

Writers use `.vee/.vee.lock` (under a custom `DIR`, if configured). A competing
writer fails clearly and may be retried. Normal exits and catchable signals
release the lock. After a crash or SIGKILL, inspect the lock's work directory and
recover any useful draft before manually removing the lock. Never remove a lock
while its process is running. Publication is staged per output file, not a
transaction across the whole site: failure can leave a recoverable raw post or
some completed output. Read the error and correct it before retrying. Failed
operations save their draft in the private `.vee/.vee-recovery/` directory and
print its path. This directory is excluded by `vee-publish`. If saving the draft
also fails, the working directory and lock are retained for manual recovery.

Use `-U` to create publicly readable files, or `-u 0077` for private files. The
caller’s umask is otherwise respected. All path components must be accessible to
your server. Filenames/directories containing newlines or tabs are unsupported
by the line-oriented companion-tool interface.

## Portability and tests

The target is POSIX `sh` and common Unix utilities. Historical pre-POSIX Bourne
shells are not a promised target. Runtime code does not require Perl. Development
tests require Perl and its core modules, including Test::More and TAP::Harness.

```sh
prove -lr t
VEE_TEST_SHELL=/bin/dash prove -lr t
VEE_TEST_SHELL='/usr/bin/busybox sh' prove -lr t
VEE_TEST_SEED=577 prove -lr t xt
```

See [TESTING.md](TESTING.md) for the CI matrix, test isolation, and coverage.
GitHub CI exercises Linux/GNU, Alpine/BusyBox, macOS, and a FreeBSD VM. A green
run establishes compatibility with those particular environments, not every
Unix system. CI logs record the environment used.

## History and licensing

Originally developed by Brett Estrade; the earlier home was
<https://git.sdf.org/pifty/vee>. Git history and contributor credits are retained.
The previous README is preserved in `docs/README-2.0-rc1.txt`.

The existing LICENSE contains WTFPL version 2. Historical embedded permission
notices are retained unchanged; this revival does not relicense prior work.
