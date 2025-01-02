#!/bin/ksh

MOVIE_DIR="/archive/media/movies"

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

src_file=$(ls "$FINAL_DIR/"*.mkv)
echo "Source File: $src_file"

# Build the destination file location
dest_dir="$MOVIE_DIR"
dest_file="$dest_dir/$JOB_NAME.mkv"
echo "Destination File: '$dest_file'"

mkdir -pm 775 "$dest_dir"
# TODO - Could we try a hard link first?
#ln "$src_file" "$dest_file"
nice -n 20 cp -v "$src_file" "$dest_file"
chmod 644 "$dest_file"
