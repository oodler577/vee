# Changes

## 2.0

Portability matrix verified on GitHub Actions: Linux (dash, bash, BusyBox ash),
Alpine/BusyBox, native macOS, and FreeBSD.

- Add a core-Perl test suite runnable with prove, including isolated subprocesses,
  byte-preservation checks, failure cases, and extended reproducible stress tests.
- Add portability CI for GNU/Linux shells, Alpine/BusyBox, macOS, and FreeBSD;
  add ShellCheck, syntax checks, and a weekly/manual extended workflow.
- Preserve piped input exactly, including backslashes and missing final newline.
- Report editor, hook, formatter, and argument failures with nonzero exit codes.
- Use fmt or fold when groff is unavailable; keep explicit groff support.
- Save drafts from failed operations in a private recovery directory.
- Stage generated output and index updates; lock writers and clean up on signals.
- Repair veecat body extraction, numeric listing order, paths with spaces, and
  portable recursive finding without find -maxdepth.
- Build Gopher maps from raw metadata and use literal printf arguments for titles.
- Retain original dates during rebuilds; refresh edited HTML/Gopher titles.
- Apply explicit CLI settings after config; respect configured directories.
- Restrict purge to known post suffixes and support Gopher-only purge.
- Repair optional publishing to include the .vee files that published links need.
- Repair bundled custom formatter examples and test dispatch/hooks without
  requiring third-party formatters.
- Document installation of all companion commands, compatibility boundaries,
  recovery behavior, and the existing extension/config interface.

Existing post filenames, raw headers, templates, hooks, and configuration entry
points are retained. See README.md for intentional behavior changes and limits.
