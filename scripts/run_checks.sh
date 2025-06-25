#!/bin/bash

# run_checks.sh - Validate package before release
# 
# This script runs all the same checks as the GitHub Actions CI workflow.
# Run this before committing changes or creating a release to ensure
# your code will pass CI.
#
# Usage: ./scripts/run_checks.sh

set -e  # Exit on error

echo "🔍 Running CI checks locally..."
echo ""

# 1. Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
cd example && flutter pub get && cd ..
echo "✅ Dependencies installed"
echo ""

# 2. Format check
echo "🎨 Checking code formatting..."
if dart format --output=none --set-exit-if-changed .; then
    echo "✅ Code formatting is correct"
else
    echo "❌ Code formatting issues found. Run 'dart format .' to fix"
    exit 1
fi
echo ""

# 3. Analyze
echo "🔎 Running static analysis..."
if flutter analyze; then
    echo "✅ Static analysis passed"
else
    echo "❌ Static analysis failed"
    exit 1
fi
echo ""

# 4. Run tests
echo "🧪 Running tests..."
if flutter test; then
    echo "✅ All tests passed"
else
    echo "❌ Tests failed"
    exit 1
fi
echo ""

# 5. Check pub score
echo "📊 Checking pub.dev score with pana..."
if ! command -v pana &> /dev/null; then
    echo "Installing pana..."
    dart pub global activate pana
fi

# Add pub-cache to PATH
export PATH="$PATH:$HOME/.pub-cache/bin"

echo "Running pana analysis..."
pana --no-warning | tee pana-output.txt

# Check the score
SCORE=$(grep "Points:" pana-output.txt | awk '{print $2}' | cut -d'/' -f1)
MAX_SCORE=$(grep "Points:" pana-output.txt | awk '{print $2}' | cut -d'/' -f2 | cut -d'.' -f1)

if [ -z "$SCORE" ]; then
    echo "❌ Could not determine pub score"
    exit 1
fi

EXPECTED_DEDUCTION=10
EXPECTED_MIN_SCORE=$((MAX_SCORE - EXPECTED_DEDUCTION))

echo ""
echo "Score: $SCORE/$MAX_SCORE"
echo "Expected minimum: $EXPECTED_MIN_SCORE (allowing $EXPECTED_DEDUCTION points for dependency constraints)"

if [ "$SCORE" -ge "$EXPECTED_MIN_SCORE" ]; then
    echo "✅ Pub score check passed"
    echo ""
    echo "Note: permission_handler is constrained to ^11.3.1 by daily_flutter 0.31.0"
    echo "This causes a 10-point deduction in the pub score."
else
    echo "❌ Pub score is too low: $SCORE/$MAX_SCORE (minimum: $EXPECTED_MIN_SCORE)"
    exit 1
fi
echo ""

# 6. Dry run publish
echo "📤 Running publish dry run..."
if flutter pub publish --dry-run; then
    echo "✅ Package is ready to publish"
else
    echo "❌ Package validation failed"
    exit 1
fi
echo ""

# 7. Build example (optional)
read -p "Do you want to build the example app? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🏗️ Building example app..."
    cd example
    
    # Detect platform
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Building for iOS simulator..."
        flutter build ios --debug --simulator
    else
        echo "Building for Android..."
        flutter build apk --debug
    fi
    
    cd ..
    echo "✅ Example app built successfully"
fi

echo ""
echo "🎉 All CI checks passed locally!"
echo ""
echo "Next steps:"
echo "1. Commit your changes: git add . && git commit -m 'your message'"
echo "2. Push to GitHub: git push origin your-branch"
echo "3. Create a PR to trigger the full CI pipeline"

# Clean up
rm -f pana-output.txt 