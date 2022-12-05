#!/bin/bash

# This script packages the ASM and WASM artefacts, and creates a draft release
# It is designed to be run by a GitHub action. To test, from the commandline, supply $VERSION and $GITHUB_TOKEN.

echo "Zipping the release archives..."
NUMERIC_VERSION=$(sed 's/^v//' <<<"$VERSION")
zip libzim_wasm_$NUMERIC_VERSION.zip libzim-wasm.*
zip libzim_asm_$NUMERIC_VERSION.zip libzim-asm.*
# If we initiated the build with a tag version, and the version doesn't already exist
if [ $DISPATCH_VERSION ]; then
  if [[ ! $(git tag) =~ "$VERSION" ]]; then
    echo "Creating a corresponding tag: $VERSION"
    git tag $VERSION
    git push origin $VERSION
  fi
fi
echo "Creating the draft release..."
REST_RESPONSE=$(
  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/openzim/javascript-libzim/releases \
    -d "{\"tag_name\":\"$VERSION\",\"target_commitish\":\"master\",\"name\":\"Release $VERSION\",\"body\":\"\",\"draft\":true,\"prerelease\":false,\"generate_release_notes\":true}"
)
echo $REST_RESPONSE
UPLOAD_URL=$(echo $REST_RESPONSE | jq -r '.upload_url')
UPLOAD_URL=$(sed -E 's/\{.+\}$//' <<<"$UPLOAD_URL")
if [ -z $UPLOAD_URL ]; then
  echo -e "\n***ERROR! We could not create the draft release!***"
  exit 2
else
  echo "Draft release created, files will be uploaded to: $UPLOAD_URL"
fi
# echo "UPLOAD_URL=$REST_RESPONSE" >> $GITHUB_OUTPUT # Use this if you need to access the URL in a later step with steps.zip-release.outputs.UPLOAD_URL
# Upload archives to the draft release
for FILE in "libzim_wasm_$NUMERIC_VERSION.zip" "libzim_asm_$NUMERIC_VERSION.zip"
do
  echo -e "\nUploading $FILE to $UPLOAD_URL?name=$FILE..."
  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/zip" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -T "$FILE" \
    "$UPLOAD_URL?name=$FILE"
done