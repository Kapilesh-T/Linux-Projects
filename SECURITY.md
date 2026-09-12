# Security Policy

This repository is a personal collection of Linux/Bash learning and
portfolio projects. There are no numbered releases and no ongoing
security-update schedule — each project's `main` branch is the only
supported version.

## Reporting a Vulnerability

If you find a security issue in any of these scripts (for example,
unsafe handling of user input, a command injection vector, or unsafe
file operations), please open a GitHub issue on this repository or
email **tkapilesh2008@gmail.com** with a short description and steps
to reproduce.

These are learning projects rather than production software, so
there's no formal SLA on response time, but I'll look at reports as
soon as I see them and fix or acknowledge the issue in the affected
project's README.

## Scope

Each project directory documents its own security considerations in
its README (see, for example, the File Organizer's "Security / Safety
Considerations" section). General good-practice notes that apply
across this repo:

- Scripts are meant to be run locally by the user who owns the files
  they operate on — none of them are designed to run with elevated
  privileges or process untrusted input from a network source.
- If a script asks for `sudo`/root, check what it's doing with that
  access before running it, as with any script from the internet.
