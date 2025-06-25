# Releasing to pub.dev

This guide explains how to release new versions of the Vapi Flutter SDK to pub.dev using GitHub releases.

## Initial Setup (One-time)

### 1. Get your pub.dev credentials

Run the helper script to get your pub.dev credentials:

```bash
./scripts/get_pub_credentials.sh
```

If you haven't logged into pub.dev yet, first run:

```bash
flutter pub login
```

**Note:** The credentials are stored in different locations depending on your OS:

- macOS: `~/Library/Application Support/dart/pub-credentials.json`
- Linux/Other: `~/.pub-cache/credentials.json`

### 2. Add credentials to GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `PUB_CREDENTIALS`
5. Value: Paste the entire JSON content from the script output (including curly braces)
6. Click "Add secret"

## Release Process

### 1. Update version in pubspec.yaml

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
  - Removing/renaming public APIs
  - Changing method signatures
  - Major behavior changes that require code updates
  
- **MINOR** (0.1.0 → 0.2.0): New features & improvements
  - Adding new methods or classes
  - Adding optional parameters
  - Performance improvements
  - Bug fixes (can also be patch)
  
- **PATCH** (0.1.0 → 0.1.1): Bug fixes only
  - Fixing bugs without changing APIs
  - Documentation updates
  - Internal refactoring

```yaml
version: 0.2.0  # Update according to your changes
```

### 2. Update CHANGELOG.md

Add a new section for your version with all changes. Use clear categories:

```markdown
## [0.2.0] - 2024-01-15

### Added
- New feature X
- Support for Y

### Fixed
- Bug where Z happened
- Issue with A

### Changed
- Improved performance of B

### Breaking Changes (for major versions only)
- Renamed method `oldName()` to `newName()`
- Removed deprecated class C
```

### 3. Commit and push changes

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.2.0"
git push origin main
```

### 4. Create a GitHub Release

1. Go to your repository on GitHub
2. Click on "Releases" → "Create a new release"
3. Click "Choose a tag" and create a new tag: `v0.2.0` (prefix with 'v')
4. Release title: `v0.2.0`
5. Release notes: Copy the relevant section from CHANGELOG.md
6. Click "Publish release"

The GitHub Action will automatically:

- Verify the package can be published (dry-run)
- Publish to pub.dev (using --force for non-interactive mode)

### 5. Monitor the release

1. Go to the "Actions" tab in your repository
2. You should see a "Publish to pub.dev" workflow running
3. Click on it to see the progress
4. If successful, your package will be live on pub.dev within a few minutes

## Troubleshooting

### If the publish workflow fails

1. **Tests failing**: Fix the tests and create a new release
2. **Credentials issue**: Verify your `PUB_CREDENTIALS` secret is set correctly
3. **Version conflict**: Make sure you've bumped the version in pubspec.yaml
4. **Package validation**: Run `flutter pub publish --dry-run` locally to check for issues

### Manual publishing (fallback)

If automated publishing fails, you can still publish manually:

```bash
flutter pub publish
```

## Best Practices

1. **Always test locally first**: Run `flutter test` and `flutter pub publish --dry-run`
2. **Follow semantic versioning strictly**:
   - Use MINOR versions (0.x.0) for new features, improvements, and fixes
   - Reserve MAJOR versions (x.0.0) for breaking changes only
   - Use PATCH versions (0.0.x) for critical bug fixes between releases
3. **Keep CHANGELOG updated**: Users rely on this to understand changes
4. **Tag consistently**: Always use `v` prefix (e.g., v0.2.0)
5. **Don't publish from branches**: Always release from the main branch
6. **Consider your users**: Breaking changes should be rare and well-documented

## Version Examples

- `0.1.0` → `0.2.0`: Added new `VapiClient.connect()` method
- `0.2.0` → `0.3.0`: Fixed audio issues and improved performance
- `0.3.0` → `1.0.0`: Breaking: Renamed `VapiClient` to `Vapi`
- `1.0.0` → `1.0.1`: Fixed critical bug in connection handling
