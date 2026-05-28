#!/bin/bash
#
# push-output.sh
#
# 在 CI 中发布新版本：构建 xcframework 并上传到 GitHub Release
# 仅在打标签的构建中运行
#

set -ev

# Only run on tagged builds
if [ -z "$TRAVIS_TAG" ]; then
    echo -e "\nBuild is not tagged"
    exit 0
fi

# Make sure tag name looks like a version number
if ! [[ $TRAVIS_TAG =~ ^[0-9\.]+(\-beta[0-9]*)?$ ]]; then
    echo -e "\nTag is not a valid version number: $TRAVIS_TAG"
    exit 1
else
    echo -e "\nTag looks like a version number: $TRAVIS_TAG"
fi

# Build xcframework using make-xcframework.sh
echo -e "\nBuilding xcframework...\n"
./Scripts/make-xcframework.sh

XCFRAMEWORK_ZIP="build/xcframework/UnrarKit.xcframework.zip"
if [ ! -f "$XCFRAMEWORK_ZIP" ]; then
    echo -e "\nxcframework zip not found: $XCFRAMEWORK_ZIP"
    exit 1
fi

# Add release to GitHub
RELEASE_NOTES=$(./Scripts/get-release-notes.py "$TRAVIS_TAG")
./Scripts/add-github-release.py $GITHUB_RELEASE_API_TOKEN $TRAVIS_REPO_SLUG $TRAVIS_TAG "$XCFRAMEWORK_ZIP" "$RELEASE_NOTES"
