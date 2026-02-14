#!/bin/bash
#
# Lou Release Script
# Automates the full release workflow:
#   1. Update version number in Xcode project
#   2. Build the app in Release mode
#   3. Package the .zip
#   4. Take a screenshot
#   5. Update the website (screenshot + download link)
#   6. Create release folder
#   7. Commit, tag, and push to remote
#   8. Create GitHub release with zip attached
#
# Usage: ./scripts/release.sh <version> [--notes "Release notes"]
#
# Example: ./scripts/release.sh 1.3-alpha --notes "Added dark mode support"
#

set -e

# Configuration
APP_NAME="Lou"
SCHEME_NAME="Lou"
PROJECT_FILE="Lou.xcodeproj"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASES_DIR="$PROJECT_DIR/Releases"
WEBSITE_DIR="$PROJECT_DIR/website"
BUILD_DIR="$PROJECT_DIR/build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${PINK}✨ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Parse arguments
VERSION=""
RELEASE_NOTES=""
SKIP_COMMIT=false
SKIP_SCREENSHOT=false
SKIP_GITHUB=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --notes)
            RELEASE_NOTES="$2"
            shift 2
            ;;
        --skip-commit)
            SKIP_COMMIT=true
            shift
            ;;
        --skip-screenshot)
            SKIP_SCREENSHOT=true
            shift
            ;;
        --skip-github)
            SKIP_GITHUB=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 <version> [options]"
            echo ""
            echo "Options:"
            echo "  --notes \"text\"     Release notes for this version"
            echo "  --skip-commit      Don't create git commit/tag"
            echo "  --skip-screenshot  Don't capture new screenshot"
            echo "  --skip-github      Don't create GitHub release"
            echo "  -h, --help         Show this help"
            echo ""
            echo "Example: $0 1.3-alpha --notes \"Added dark mode\""
            exit 0
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                print_error "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$VERSION" ]]; then
    print_error "Version is required"
    echo "Usage: $0 <version> [--notes \"Release notes\"]"
    echo "Example: $0 1.3-alpha --notes \"Bug fixes and improvements\""
    exit 1
fi

# Extract major.minor for Xcode (strip -alpha, -beta, etc.)
MARKETING_VERSION=$(echo "$VERSION" | sed 's/-.*$//')

cd "$PROJECT_DIR"

echo -e "${PINK}"
echo "╔═══════════════════════════════════════════╗"
echo "║          Lou Release Script               ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo "Version: v$VERSION"
echo "Marketing Version: $MARKETING_VERSION"
[[ -n "$RELEASE_NOTES" ]] && echo "Notes: $RELEASE_NOTES"
echo ""

# Step 1: Update version in Xcode project
print_step "Updating version in Xcode project..."

# Update MARKETING_VERSION
sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = $MARKETING_VERSION;/g" "$PROJECT_FILE/project.pbxproj"

# Increment build number
CURRENT_BUILD=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE/project.pbxproj" | grep -o '[0-9]*' | head -1)
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT_FILE/project.pbxproj"

print_success "Version set to $MARKETING_VERSION (build $NEW_BUILD)"

# Step 2: Build the app
print_step "Building $APP_NAME in Release mode..."

xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build 2>&1 | grep -E "(error:|warning:|BUILD)" | grep -v "Metadata extraction skipped" || true

# Find the built app
BUILT_APP=$(find "$BUILD_DIR" -name "$APP_NAME.app" -path "*/Release/*" 2>/dev/null | head -1)

if [[ ! -d "$BUILT_APP" ]]; then
    print_error "Build failed - could not find $APP_NAME.app"
    exit 1
fi

print_success "Build successful: $BUILT_APP"

# Step 3: Create release folder
print_step "Creating release folder..."

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
RELEASE_FOLDER="$RELEASES_DIR/${APP_NAME}_v${VERSION}_${TIMESTAMP}"
mkdir -p "$RELEASE_FOLDER"

# Copy app to release folder
cp -R "$BUILT_APP" "$RELEASE_FOLDER/"
print_success "App copied to $RELEASE_FOLDER"

# Step 4: Create zip package
print_step "Creating zip package..."

ZIP_NAME="${APP_NAME}-v${VERSION}.zip"
cd "$RELEASE_FOLDER"
zip -r -q "$ZIP_NAME" "$APP_NAME.app"
cd "$PROJECT_DIR"

print_success "Created $ZIP_NAME"

# Step 5: Take screenshot (unless skipped)
if [[ "$SKIP_SCREENSHOT" == false ]]; then
    print_step "Capturing screenshot..."

    # Kill any existing instance
    pkill -x "$APP_NAME" 2>/dev/null || true
    sleep 0.5

    # Capture screenshot
    "$BUILT_APP/Contents/MacOS/$APP_NAME" --screenshot --output "$WEBSITE_DIR/img/Screenshot.png" &
    SCREENSHOT_PID=$!

    # Wait for it to complete
    for i in {1..15}; do
        if ! kill -0 $SCREENSHOT_PID 2>/dev/null; then
            break
        fi
        sleep 1
    done
    kill $SCREENSHOT_PID 2>/dev/null || true

    if [[ -f "$WEBSITE_DIR/img/Screenshot.png" ]]; then
        print_success "Screenshot updated"
    else
        print_warning "Screenshot capture may have failed"
    fi
else
    print_warning "Skipping screenshot capture"
fi

# Step 6: Update website download link
print_step "Updating website download link..."

# Update the download link in index.html
OLD_LINK_PATTERN='href="https://github.com/drewmatthews/lou/releases/latest/download/Lou-v[^"]*\.zip"'
NEW_LINK="href=\"https://github.com/drewmatthews/lou/releases/latest/download/${ZIP_NAME}\""

sed -i '' "s|$OLD_LINK_PATTERN|$NEW_LINK|g" "$WEBSITE_DIR/index.html"

# Update version number in download note
sed -i '' "s|<p class=\"download-note\">v[^<]*·|<p class=\"download-note\">v$VERSION ·|g" "$WEBSITE_DIR/index.html"

print_success "Website download link updated to $ZIP_NAME"

# Step 7: Copy zip to website releases folder (for local hosting backup)
print_step "Copying zip to website releases..."

mkdir -p "$WEBSITE_DIR/releases/latest/download"
cp "$RELEASE_FOLDER/$ZIP_NAME" "$WEBSITE_DIR/releases/latest/download/"

# Also keep a Lou.zip symlink for convenience
cd "$WEBSITE_DIR/releases/latest/download"
rm -f Lou.zip
ln -s "$ZIP_NAME" Lou.zip
cd "$PROJECT_DIR"

print_success "Zip copied to website/releases"

# Step 8: Create release notes file
print_step "Creating release notes..."

RELEASE_NOTES_FILE="$RELEASE_FOLDER/RELEASE_NOTES.md"
cat > "$RELEASE_NOTES_FILE" << EOF
# Lou v$VERSION

Released: $(date +"%Y-%m-%d")

## Changes

${RELEASE_NOTES:-"- Bug fixes and improvements"}

## Installation

1. Download \`$ZIP_NAME\`
2. Extract and drag \`Lou.app\` to Applications
3. First launch: Right-click → Open (app is unsigned)

## Requirements

- macOS 13 (Ventura) or newer
- Claude Code installed
EOF

print_success "Release notes created"

# Step 9: Git operations (unless skipped)
if [[ "$SKIP_COMMIT" == false ]]; then
    print_step "Git operations..."

    # Check if there are changes to commit
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "Release v$VERSION

${RELEASE_NOTES:-"Bug fixes and improvements"}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

        # Create tag
        git tag -a "v$VERSION" -m "Release v$VERSION"

        print_success "Committed and tagged v$VERSION"

        # Push to remote
        print_step "Pushing to remote..."
        git push && git push --tags
        print_success "Pushed commits and tags to remote"
    else
        print_warning "No changes to commit"

        # Check if tag exists and push it if needed
        if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
            if ! git ls-remote --tags origin | grep -q "refs/tags/v$VERSION"; then
                print_step "Pushing tag to remote..."
                git push --tags
                print_success "Pushed tag v$VERSION to remote"
            fi
        fi
    fi
else
    print_warning "Skipping git commit/tag"
fi

# Step 10: Create GitHub release (unless skipped)
if [[ "$SKIP_GITHUB" == false ]]; then
    print_step "Creating GitHub release..."

    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) not found. Install with: brew install gh"
        print_warning "Skipping GitHub release creation"
    else
        # Check if release already exists
        if gh release view "v$VERSION" --repo drewmatthews/lou &> /dev/null; then
            print_warning "Release v$VERSION already exists on GitHub"
        else
            # Create the release
            RELEASE_BODY="## Changes

${RELEASE_NOTES:-"- Bug fixes and improvements"}

## Installation

1. Download \`$ZIP_NAME\`
2. Extract and drag \`Lou.app\` to Applications
3. First launch: Right-click → Open (app is unsigned)

## Requirements

- macOS 13 (Ventura) or newer
- Claude Code installed"

            gh release create "v$VERSION" \
                "$RELEASE_FOLDER/$ZIP_NAME" \
                --repo drewmatthews/lou \
                --title "Lou v$VERSION" \
                --notes "$RELEASE_BODY"

            print_success "GitHub release created: https://github.com/drewmatthews/lou/releases/tag/v$VERSION"
        fi
    fi
else
    print_warning "Skipping GitHub release"
fi

# Summary
echo ""
echo -e "${PINK}╔═══════════════════════════════════════════╗"
echo "║            Release Complete!              ║"
echo "╚═══════════════════════════════════════════╝${NC}"
echo ""
echo "Version:     v$VERSION"
echo "Build:       $NEW_BUILD"
echo "Release:     $RELEASE_FOLDER"
echo "Zip:         $ZIP_NAME"
echo "GitHub:      https://github.com/drewmatthews/lou/releases/tag/v$VERSION"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test the app from: $RELEASE_FOLDER/$APP_NAME.app"
echo "  2. Deploy website changes (if not using GitHub Pages)"
echo ""
