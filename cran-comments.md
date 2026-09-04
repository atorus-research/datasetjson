# Submission 0.4.0

- JSON parsing and serialization moved into the package, using the bundled
  `yyjson` C library. This is the first release of `datasetjson` to contain
  compiled code.
- Removes the `yyjsonr` dependency, and moves `jsonvalidate` to `Suggests`.
  `Imports` is now only `hms`.
- Adds support for the Dataset NDJSON and Dataset JSON Compressed (`.dsjc`)
  representations of the CDISC Dataset JSON standard.
- Corrects a loss of numeric precision when reading files.

## Bundled and linked code

- `src/yyjson.c` and `src/yyjson.h` are the `yyjson` C library
  (https://github.com/ibireme/yyjson), version 0.12.0, included unmodified.
  It is released under the MIT license. The copyright holder is recorded in
  `Authors@R` with role `cph`, in the `Copyright` field of DESCRIPTION, and in
  `inst/COPYRIGHTS`, which reproduces the license in full.
- The package links `zlib` (`PKG_LIBS = -lz`), which the Dataset JSON
  Compressed format requires. `zlib` is required by R itself on all platforms.

## Test environments

- local macOS (aarch64), R 4.5.1
- GitHub Actions: Ubuntu (release, devel, oldrel-1, oldrel-3), macOS (release),
  Windows (release)
- win-builder (release, devel)
- macOS builder

## R CMD CHECK Results

- Possibly misspelled words in description are acronyms spelled correctly
- file/directories found are false positives
