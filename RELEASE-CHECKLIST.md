# Release checklist

This checklist is mandatory for every published version.

## Documentation gate

Before publishing any crate, archive, package repository, or GitHub release:

- [ ] Update the root `CHANGELOG.md` with the final version, date, user-visible
      changes, distribution changes, compatibility notes, and explicit limits.
- [ ] Add `docs/releases/<tag>.md` with release-specific notes and exact
      source/artifact identity.
- [ ] Add `docs/<previous>-to-<current>.md` with the complete comparison,
      crate/package scope, branch decisions, evidence, and deferred work.
- [ ] Link both documents from `CHANGELOG.md` and the root `README.md`.
- [ ] Remove preparation-only wording such as “pending”, “candidate”, or
      “unreleased” from final public documents.
- [ ] Review the documents against the final publication receipt before merge.

Documentation is part of the release artifact. A package is not release-ready
until the changelog and full comparison are committed to this repository; local
evidence files and a GitHub release body alone do not satisfy this gate.

## Channel gates

- [ ] Verify crates.io publication order and public versions.
- [ ] Verify signed APT/RPM metadata and consumer installation.
- [ ] Verify Chocolatey packaging with the Chocolatey release gate.
- [ ] Record exact source SHA, artifact hashes, signing fingerprints, and
      remaining architecture or signing limitations.
