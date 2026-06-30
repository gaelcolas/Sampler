# Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

If you want to contribute code to this repository and is new to contributing
on GitHub then start with the guide [Getting Started as a Contributor](https://dsccommunity.org/guidelines/getting-started/).

## Running the Tests

If want to know how to run this module's tests you can look at the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests).

## Changelog

All user-visible changes must have an entry in `CHANGELOG.md` under the
`## [Unreleased]` section. Build, pipeline, CI, and Copilot-instruction-only
changes do not need entries.

> **Important:** `CHANGELOG.md` must contain only ASCII characters. Non-ASCII
> characters (Unicode arrows, em-dashes, smart quotes, etc.) are
> embedded verbatim into the built module manifest's `ReleaseNotes` field.
> Windows PowerShell 5.1 cannot parse a module manifest that contains non-ASCII
> characters when the file is UTF-8 encoded without a BOM (which is the default
> on Linux and macOS). Use plain ASCII equivalents: `->` instead of `->`,
> `-` instead of `--`, straight quotes instead of curly quotes.
>
> The QA test suite enforces this rule - a PR with non-ASCII characters in
> `CHANGELOG.md` will fail the `Changelog contains only ASCII characters` test.
