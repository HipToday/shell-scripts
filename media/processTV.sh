#!/bin/sh

friendly_title="Seinfeld"
# Usually period-separated
filename_title="Seinfeld"
season="02"

dest_dir="/archive/media/tvshows/$friendly_title/Season $season"

mkdir -p "$dest_dir"

for src_dir in $filename_title.S$season*; do
	echo "$src_dir"
	video_filename=$(ls "$src_dir/"*.mkv)
	#echo "$video_filename"
	ln "$video_filename" "$dest_dir/$src_dir.mkv"
done

