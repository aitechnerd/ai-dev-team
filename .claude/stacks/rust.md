# Rust Stack Profile

## Package Manager
- Cargo (Cargo.toml, Cargo.lock)
- Workspace support: check for `[workspace]` in root Cargo.toml

## Build & Run
- Build: `cargo build`, `cargo build --release`
- Run: `cargo run`
- Check (no binary): `cargo check` — faster than full build

## Testing
- Framework: built-in `#[test]`, `#[cfg(test)]`
- Run: `cargo test`, `cargo test -- --nocapture` (show output)
- Integration tests: `tests/` directory
- Doc tests: code in `///` comments
- Benchmarks: `cargo bench` (requires nightly or criterion crate)
- Coverage: `cargo tarpaulin` or `cargo llvm-cov`
- Convention: tests in same file under `#[cfg(test)] mod tests { ... }`

## Linting & Formatting
- Linter: `cargo clippy -- -W clippy::pedantic -W clippy::nursery`
- Formatter: `cargo fmt`, check: `cargo fmt -- --check`
- Clippy JSON: `cargo clippy --message-format=json`

## Security Scanners
- `cargo audit` — dependency CVEs (RustSec database)
- `cargo deny` — licenses, bans, duplicates, advisories (needs deny.toml)
- `cargo-geiger` — unsafe code audit across dependency tree
- `cargo-machete` — unused dependencies
- Semgrep — has Rust rules for SAST
- Gitleaks / Trivy — language-agnostic secrets + CVEs

## Common Vulnerabilities
- Unsafe blocks: memory safety bypassed, review all `unsafe` usage
- Integer overflow: debug panics vs release wraps — use checked_* methods
- Unwrap/expect: panics in production — prefer `?` operator or proper error handling
- Path traversal: `std::path::Path` doesn't sanitize — validate user paths
- Command injection: `std::process::Command` with user input
- Deserialization: serde with untrusted input can cause DoS
- Supply chain: typosquatting on crates.io — review new deps

## Dependencies
- Lockfile: Cargo.lock (commit for binaries, optional for libraries)
- Audit: `cargo audit`, `cargo deny check`
- Update: `cargo update`
- Minimal versions: `cargo +nightly -Z minimal-versions check`

## DevOps
- Docker: use multi-stage builds (builder + runtime), `FROM rust:slim AS builder`
- Binary: single static binary possible with `musl` target
- CI: `cargo check` → `cargo clippy` → `cargo test` → `cargo build --release`
- Cross-compile: `cross` tool or `--target` flag
- Release: `cargo build --release`, strip with `strip target/release/binary`

## Architecture Patterns
- Error handling: `thiserror` for libraries, `anyhow` for applications
- Async: `tokio` runtime, `async-trait` for trait async methods
- CLI: `clap` for argument parsing
- Serialization: `serde` + `serde_json`/`serde_yaml`
- Logging: `tracing` (preferred over `log`)
- Config: `config` crate or `figment`
- Module structure: `lib.rs` for library, `main.rs` for binary, `mod.rs` for modules

## Code Review Focus
- Ownership/borrowing: unnecessary clones, lifetime issues
- Error propagation: `unwrap()` in non-test code is a red flag
- Unsafe: every `unsafe` block needs justification
- Performance: unnecessary allocations, missing `&str` vs `String`
- Concurrency: `Arc<Mutex<>>` vs channels, deadlock potential
