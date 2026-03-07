#!/bin/bash

TV_SHOW_DIR="/mnt/archive/media/tvshows"
SCRIPT_DIR="/var/lib/sabnzbdplus/.sabnzbd/scripts"

echo "SAB_FINAL_NAME: $SAB_FINAL_NAME"
echo "SAB_FILENAME: $SAB_FILENAME"
echo "SAB_COMPLETE_DIR: $SAB_COMPLETE_DIR"
echo "SAB_PP_STATUS: $SAB_PP_STATUS"

# Loop through all command-line parameters
i=1
for arg in "$@"
do
    echo "Argument $i: $arg"
    ((i++))
done

# See https://sabnzbd.org/wiki/configuration/4.3/scripts/post-processing-scripts
FINAL_DIR="$1"
JOB_NAME="$3"

# Get the first .mkv file in the final directory and verify it exists
src_file=$(ls -1 "$FINAL_DIR/"*.mkv | head -n 1)
if [ -z "$src_file" ]; then
    echo "Error: No .mkv file found in $FINAL_DIR"
    exit 1
fi
echo "Source File: $src_file"

# Get everything before the "SxxExx" part of the job name
show_name=$(echo "$JOB_NAME" | sed "s/\(.*\)[sS][0-9]\{1,\}[eE][0-9]\{1,\}.*/\1/")
# Replace periods with spaces and trim spaces off the end
show_name=$(echo "$show_name" | sed  "s/\./ /g" | sed "s/ *$//")
echo "Show Name: $show_name"

# Get the season
season=$(echo "$JOB_NAME" | sed "s/.*[sS]\([0-9]\{1,\}\)[eE][0-9]\{1,\}.*/\1/")
echo "Season: $season"

# Build the destination file location
show_dir="$TV_SHOW_DIR/$show_name"
season_dir="$show_dir/Season $season"
dest_file="$season_dir/$JOB_NAME.mkv"
echo "Destination File: '$dest_file'"

mkdir -pm 775 "$season_dir"
chmod 775 "$show_dir"
# TODO - Could we try a hard link first?
#ln "$src_file" "$dest_file"
nice -n 20 cp -v "$src_file" "$dest_file"
chmod 644 "$dest_file"

if [ -e "$SCRIPT_DIR/plex.sh" ]; then
    . "$SCRIPT_DIR/plex.sh"
    echo "PLEX_API_URL: $PLEX_API_URL"
    echo -n "Triggering Plex Library scan..."
    curl -s "$PLEX_API_URL/library/sections/$PLEX_API_SHOWS_KEY/refresh?X-Plex-Token=$PLEX_API_TOKEN"
    echo "Done."
fi

# If we got here, all went well, so let's clean up the final directory
echo "Cleaning up $FINAL_DIR"
rm -rf "$FINAL_DIR"
