#!/bin/bash

# Function to increment version number
increment_version() {
    local version=$1
    local part=$2
    IFS='.' read -r -a parts <<< "$version"
    if [ "$part" == "major" ]; then
        parts[0]=$((parts[0] + 1))
        parts[1]=0
        parts[2]=0
    elif [ "$part" == "minor" ]; then
        parts[1]=$((parts[1] + 1))
        parts[2]=0
    elif [ "$part" == "patch" ]; then
        parts[2]=$((parts[2] + 1))
    fi
    echo "${parts[0]}.${parts[1]}.${parts[2]}"
}

# Function to increment build number
increment_build_number() {
    local build_number=$1
    echo $((build_number + 1))
}

# Read current version and build number from pubspec.yaml
current_version=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
current_build_number=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f2)

echo "Current version: $current_version"
echo "Current build number: $current_build_number"

# Ask user which to increment
echo "Which part of the version would you like to increment? (major/minor/patch)"
read part
new_version=$(increment_version $current_version $part)
new_build_number=$(increment_build_number $current_build_number)

# Update pubspec.yaml with new version and build number
#sed -i '' "s/^version: .*/version: $new_version+$new_build_number/" pubspec.yaml

echo "Updated version to $new_version and build number to $new_build_number"

# Clean th ws and install deppendencies
flutter clean
flutter pub get
cd ios; pod install; cd ..

# Perform a flutter build for web, ios, and appbundle
flutter build web
flutter build ipa
flutter build apk
flutter build appbundle

# copy web to pages, then zip the contents of the web build into a file named Web.zip
cd build/web
    cp -r * ../../docs/
    zip -r Web.zip .
cd ../..

# Ask user for release description
echo "Enter the description for the release:"
read release_description

# Get the latest release tag
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
# Get the commit messages since the latest release
commit_messages=$(git log $latest_tag..HEAD --pretty=format:"- %s")
# Append commit messages to the release description
release_description="$release_description

### Commits since last release:
$commit_messages"

# Create a GitHub release
gh release create "v$new_version" \
    --title "Release $new_version" \
    --notes "$release_description" \
    build/web/Web.zip \
    build/ios/ipa/*.ipa \
    build/app/outputs/flutter-apk/app-release.apk

echo "GitHub release created successfully."
# Open a browser to the new release
open "https://github.com/javaplus/mad_scientist_app/releases/tag/v$new_version"

# Ask the user to review file changes before committing and pushing
echo "Please review the file changes:"
git status
echo "Do you want to proceed with committing and pushing the changes? (yes/no)"
read proceed_with_commit

if [ "$proceed_with_commit" == "yes" ]; then
    # Commit and push the changes to the repository
    git add .
    git commit -m "Release version $new_version"
    git push origin main
    echo "Changes committed and pushed successfully."
else
    echo "Commit and push aborted."
fi

# Prompt the user if they should upload the IPA to the app store
echo "Do you want to upload the IPA to the App Store? (yes/no)"
read upload_to_app_store

if [ "$upload_to_app_store" == "yes" ]; then
    # Upload the IPA to Transporter app
    echo "Uploading IPA to Transporter app..."
    xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa --username "greg@shaykos.com" --password "ksxf-dyqp-ftdf-qsyk"

    echo "IPA uploaded to Transporter app successfully."
fi

