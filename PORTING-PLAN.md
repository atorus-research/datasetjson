# Native JSON parsing for datasetjson

## Why

Every current read path ends in R's `as.double()`, which is not correctly rounded
(`as.double("1234.5678901234567")` → `1234.5678901234569`). Combined with
`promote_num_to_string`'s `snprintf("%.6f")`, floats below ~5e-7 are silently read
back as `0` (issue #97).

No option in yyjsonr closes this, because every option still hands R a string.
Parsing the number to a `double` in C and writing it straight into a `REALSXP` is
the only path to exactness.

Secondary benefit: datasetjson knows every column's type from `columns` *before*
it touches `rows`. A schema-directed parser allocates typed vectors up front and
skips the character matrix, the `snprintf`, and the `as.double()` pass entirely.

## Approach

Vendor **yyjson** (the MIT C library, ibireme/yyjson 0.12.0) — not a fork of
yyjsonr's general-purpose R glue. yyjson is a two-file, zero-dependency C99
library, actively maintained. The Dataset-JSON-specific binding is ours.

## Phases

- [x] **0. Vendor + infrastructure** — `src/yyjson.{c,h}`, `Makevars`, `init.c`,
      `useDynLib`, `inst/COPYRIGHTS`
- [x] **1. Native reader** — schema-directed parse into typed vectors.
      Closes the precision bug. Highest value; do this first.
- [x] **2. Native writer** — serialize rows as arrays without the `unname()` trick
      and without `format()`-to-character for decimals
- [ ] **3. NDJSON** — read + write, removing the R-level row-by-row fallback in
      `write_dataset_ndjson.R`
- [ ] **4. Drop the yyjsonr dependency**

## Type mapping (CDISC Dataset-JSON v1.1)

| dataType | targetDataType | JSON  | R vector | parse |
|----------|----------------|-------|----------|-------|
| string   | —              | string  | STRSXP | — |
| integer  | —              | integer | INTSXP | `yyjson_get_sint` + range check |
| decimal  | decimal        | string  | REALSXP | C `strtod` (correctly rounded) |
| float    | —              | number  | REALSXP | `yyjson_get_num` |
| double   | —              | number  | REALSXP | `yyjson_get_num` |
| boolean  | —              | boolean | LGLSXP | `yyjson_get_bool` |
| date     | —              | string  | STRSXP | — |
| date     | integer        | integer | REALSXP | → `Date` in R |
| datetime | —              | string  | STRSXP | — |
| datetime | integer        | integer | REALSXP | → `POSIXct` in R |
| time     | —              | string  | STRSXP | — |
| time     | integer        | integer | REALSXP | → `hms` in R |

Date/time class construction stays in R (`date_time_conversions()`); C only
delivers the correct primitive type.

## Contract

`.Call(C_read_dsjson_file, path)` / `.Call(C_read_dsjson_str, txt)` return a list
shaped like the current `yyjsonr` output, except `rows` is replaced by `data`: a
list of already-typed column vectors. `read_dataset_json()` assembles the
data.frame and attributes as it does today.

## Not doing

- Rust. The engine is ~3-6% of read time; the cost is a toolchain requirement that
  validated pharma environments often cannot satisfy.
- Forking `R-yyjson-parse.c` (75KB of general-purpose JSON↔R mapping). We need a
  small fraction of it and would inherit the maintenance.
