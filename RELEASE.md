# Releasing to pub.dev

This guide explains how to release new versions of the Vapi Flutter SDK to pub.dev using GitHub releases.

## Initial Setup (One-time)

### 1. Get pub.dev credentials

```bash
./scripts/get_pub_credentials.sh
```

If not logged in yet: `flutter pub login`

### 2. Add to GitHub Secrets

1. Go to Settings → Secrets and variables → Actions
2. Add new secret: `PUB_CREDENTIALS`
3. Paste the JSON content from step 1

## Release Process

### 1. Update version in pubspec.yaml

Follow semantic versioning:

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
- **MINOR** (0.1.0 → 0.2.0): New features, improvements, bug fixes
- **PATCH** (0.1.0 → 0.1.1): Bug fixes only

```yaml
version: 0.2.0  # Update accordingly
```

### 2. Update CHANGELOG.md

```markdown
## [0.2.0] - 2025-06-25

### Added
- New feature X

### Fixed
- Bug where Z happened

### Changed
- Improved performance of B

### Breaking Changes  # For major versions only
- Renamed method `oldName()` to `newName()`
```

### 3. Commit and push

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.2.0"
git push origin main
```

### 4. Create GitHub Release

1. Go to Releases → Create a new release
2. Create tag: `v0.2.0` (with 'v' prefix)
3. Title: `v0.2.0`
4. Copy notes from CHANGELOG.md
5. Publish release

The GitHub Action will automatically publish to pub.dev.

### 5. Monitor

Check the Actions tab for the "Publish to pub.dev" workflow status.

## Troubleshooting

- **Tests failing**: Fix and create new release
- **Credentials issue**: Verify `PUB_CREDENTIALS` secret
- **Version conflict**: Ensure version bump in pubspec.yaml
- **Manual fallback**: `flutter pub publish`

## Best Practices

1. Test locally: `flutter test` and `flutter pub publish --dry-run`
2. Follow semantic versioning strictly
3. Keep CHANGELOG updated
4. Always release from main branch
5. Use consistent tag format: `vX.Y.Z`

## Version Examples

- `0.1.0`
