# Copilot Instructions

## CRITICAL: Python-only codebase

All wheel build logic lives exclusively in `src/wheelbuilder/`. **Never read, edit, or reference any Swift files** (`Sources/`, `*.swift`, `Package.swift`, etc.). They are legacy and irrelevant to the current implementation.

- All recipes are in `src/wheelbuilder/wheels/`
- All base protocols/classes are in `src/wheelbuilder/protocols.py`
- All platform info is in `src/wheelbuilder/platforms.py`
- The CLI entry point is `src/wheelbuilder/cli.py`
- GitHub Actions workflows are in `.github/workflows/`

If a Swift file is referenced in context, ignore it.
