# Working on vee

Keep the runtime POSIX shell with common Unix utilities. Perl belongs in tests,
not in the installed publisher. Preserve existing raw post files, filenames,
metadata headers, templates, hooks, and configuration interfaces.

Run `prove -lr t` for changes; run `prove -lr t xt` when changing writes, rebuilds,
locking, or input handling. Add a regression test for each fixed defect. Run
`VEE_TEST_SHELL=/bin/dash prove -lr t` and BusyBox when available. A different
shell on Linux does not establish BSD userland compatibility: consult CI.

Do not claim a final release until the portability matrix passes. Keep changes
on the release branch for review; do not create a release tag or merge solely
because a local test run passed. Retain historical licensing and credits.
