# Testing vee

Run from the repository root:

```sh
prove -lr t
prove -lv t/04-failures.t
VEE_TEST_SHELL=/bin/dash prove -lr t
VEE_TEST_SHELL='/usr/bin/busybox sh' prove -lr t
prove -lr t xt
```

The harness uses only core Perl modules. Each test file creates disposable blogs,
isolates HOME, clears shell startup variables, supplies stdin, captures stdout
and stderr separately, and enforces a 15-second subprocess timeout. No real
publication directory, network connection, or interactive editor is used.

Without VEE_TEST_SHELL, executables use their real shebangs. With it, wrappers
force all six commands through the chosen shell, including companion commands
launched by vee itself. This tests interpreters; it does not substitute their
utilities. Alpine tests use actual BusyBox utilities; macOS and FreeBSD use their
native userland. Do not put GNU replacements first on PATH in BSD jobs.

Tests cover CLI validation, source-byte preservation, HTML/Gopher modes, raw
metadata extraction, numeric post ordering, custom paths/config/templates,
editing, rebuilds, purge boundaries, formatters, failures, time zones, and
permissions. Permission-denial assertions skip explicitly when run as root;
Ubuntu/macOS and the Alpine job run them as ordinary users.

Extended tests in xt/ exercise seeded generated input, bulk rebuilds, concurrent
writers, and termination during a hook. Reproduce failures using the printed
VEE_TEST_SEED. They run manually or weekly in GitHub Actions; no external service
is needed to run them locally.

The ordinary portability workflow runs on every push and pull request. It tests
Ubuntu under dash, bash, and BusyBox ash; native macOS; Alpine; and a FreeBSD VM.
Ubuntu installs groff while Alpine omits it, exercising both default formatter
paths. Static analysis runs ShellCheck at warning severity and sh -n. Actions are
pinned to commit IDs. All workflow tokens have read-only repository access.

Tests verify behavior, not every implementation detail. Generated timestamps
are allowed to vary; input bytes and rebuilt Gopher maps are compared exactly.
The finite corpus and stress suite are not a proof against every possible
failure. In particular, whole-site transactions, SIGKILL cleanup, arbitrary
binary input, and filename newlines/tabs are not promised.
