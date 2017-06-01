#!/usr/bin/env bash
#
# Builds mixtape for development and plugin deployment
#
# usage:
#
#     ./scripts/build_mixtape.sh
#
# Assumes a special file called `.mixtapefile` is present at project root.
# Generates it if absent.

set -e;

function expect_git() {
  command -v git >/dev/null 2>&1 || {
    echo "No Git found. Exiting.";
    exit 1;
  }
}

function expect_directory() {
  if [ ! -d "$1" ]; then
    echo "Not a directory: $1. Exiting";
    exit 1;
  fi
}

expect_git

MIXTAPE_TEMP_PATH="./tmp/mt";
MIXTAPE_REPO="https://github.com/Automattic/mixtape/";
MIXTAPEFILE_NAME=".mixtapefile";
MIXTAPE_PATH="${MIXTAPE_PATH-$MIXTAPE_TEMP_PATH}"

if [ "$MIXTAPE_PATH" == "$MIXTAPE_TEMP_PATH" ]; then
  if [ ! -d "$MIXTAPE_PATH" ]; then
    mkdir -p "$MIXTAPE_PATH";
    git clone "$MIXTAPE_REPO" "$MIXTAPE_PATH";
  fi
fi

expect_directory "$MIXTAPE_PATH";

if [ ! -f "$MIXTAPEFILE_NAME" ]; then
  echo "No .mixtapefile found. Generating one from Mixtape repo HEAD";
  MIXTAPE_REPO_SHA="$(cd $MIXTAPE_PATH && git rev-parse HEAD)";

  echo "sha=$MIXTAPE_REPO_SHA" >> "$MIXTAPEFILE_NAME";
  echo "prefix=WPJM_REST" >> "$MIXTAPEFILE_NAME";
  echo "destination=lib/wpjm_rest" >> "$MIXTAPEFILE_NAME";

  echo "$MIXTAPEFILE_NAME Generated:";
  echo "";
  cat "$MIXTAPEFILE_NAME";
fi

mt_current_sha="$(cat "$MIXTAPEFILE_NAME" | grep -o 'sha=[^"]*' | sed 's/sha=//')";
mt_current_prefix="$(cat "$MIXTAPEFILE_NAME" | grep -o 'prefix=[^"]*' | sed 's/prefix=//')";
mt_current_destination="$(pwd)/$(cat "$MIXTAPEFILE_NAME" | grep -o 'destination=[^"]*' | sed 's/destination=//')";

echo "============= Building Mixtape =============";
echo "";
echo "SHA         = $mt_current_sha";
echo "PREFIX      = $mt_current_prefix";
echo "DESTINATION = $mt_current_destination";
echo "";

expect_directory "$mt_current_destination";

cd $MIXTAPE_PATH;
mt_repo_current_sha="$(git rev-parse HEAD)";
# echo "current mixtape repo sha is: $mt_repo_current_sha. Project is sha is $mt_current_sha";

git checkout "$mt_current_sha" >/dev/null 2>&1;
./scripts/new_project.sh "$mt_current_prefix" "$mt_current_destination" >/dev/null;

if [ $? -ne 0 ]; then
  echo "Something is wrong with the file generation, Exiting" >&2;
  git checkout "$mt_repo_current_sha" >/dev/null 2>&1;
  exit 1;
else
  echo "Generation done!";
fi
