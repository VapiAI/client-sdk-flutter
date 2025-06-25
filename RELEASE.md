# Releasing to pub.dev

This guide explains how to release new versions of the Vapi Flutter SDK to pub.dev using GitHub releases.

## Initial Setup (One-time)

### Enable Automated Publishing on pub.dev

1. Go to [pub.dev](https://pub.dev) and sign in
2. Navigate to your package page
3. Go to the **Admin** tab
4. Under **Automated Publishing**, click **Enable publishing from GitHub Actions**
5. Enter your repository: `<your-github-username>/<your-repository-name>`
6. Set tag pattern: `v{{version}}`

**Note:** You must be a verified publisher or have uploader permissions on the package.

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

### 4. Create and push tag

```bash
# Create tag matching the version
git tag v0.2.0

# Push the tag to trigger publishing
git push origin v0.2.0
```

The GitHub Action will automatically publish to pub.dev using OIDC authentication.

### 5. Monitor

Check the Actions tab for the "Publish to pub.dev" workflow status.

### 6. Create GitHub Release (Optional)

After successful publishing, you can create a GitHub release:

1. Go to Releases → Create a new release
2. Choose existing tag: `v0.2.0`
3. Title: `v0.2.0`
4. Copy notes from CHANGELOG.md
5. Publish release

## Troubleshooting

- **Workflow not triggering**: Ensure tag matches pattern `v{{version}}`
- **Authentication failed**: Verify automated publishing is enabled on pub.dev
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
