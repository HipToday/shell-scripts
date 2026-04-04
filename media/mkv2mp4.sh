#!/bin/ksh
# This script converts MKV files in the current directory to a format
# compatible with Uconnect in the Chrysler Pacifica. It checks the audio codec
# of each MKV file and re-encodes it to AAC if it's not already compatible. The
# video stream is copied without re-encoding for speed and quality preservation.

# --- Configuration ---
FFMPEG_CMD="ffmpeg"
FFPROBE_CMD="ffprobe"
OUTPUT_EXTENSION="mp4"
# List of audio codecs that are usually compatible with Uconnect in the Chrysler Pacifica
COMPATIBLE_AUDIO="aac"

echo "Starting MKV to MP4 conversion with conditional audio re-encoding..."
echo "---"

# Find all MKV files in the current directory
for INPUT_FILE in *.mkv; do
    # Check if a file was actually found (avoids running on literal '*.mkv')
    if [[ ! -e "$INPUT_FILE" ]]; then
        echo "No .mkv files found in the current directory."
        break
    fi

    # 1. Strip the file extension (.mkv) to get the base name
    # The '##*.' removes the shortest match from the beginning up to the last dot (including the dot).
    BASE_NAME=${INPUT_FILE%.mkv}

    # 2. Construct the output file name
    OUTPUT_FILE="${BASE_NAME}.${OUTPUT_EXTENSION}"

    echo "Processing: ${INPUT_FILE}"

    # 1. Use ffprobe to get the audio codec name of the first audio stream
    AUDIO_CODEC=$("${FFPROBE_CMD}" -v error \
                                   -select_streams a:0 \
                                   -show_entries stream=codec_name \
                                   -of default=noprint_wrappers=1:nokey=1 \
                                   "${INPUT_FILE}")

    # Remove any extra whitespace from the codec name
    AUDIO_CODEC=$(echo "$AUDIO_CODEC" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    
    # Get the number of audio channels
    AUDIO_CHANNELS=$("${FFPROBE_CMD}" -v error \
                                      -select_streams a:0 \
                                      -show_entries stream=channels \
                                      -of default=noprint_wrappers=1:nokey=1 \
                                      "${INPUT_FILE}")
    
    # Remove any extra whitespace from the channel count
    AUDIO_CHANNELS=$(echo "$AUDIO_CHANNELS" | tr -d '[:space:]')
    
    # Set the default copy parameters (copy everything)
    VIDEO_COPY_PARAM="-c:v copy"
    AUDIO_PARAM="-c:a copy"

    # 2. Check if the audio codec needs re-encoding
    if [[ "$AUDIO_CODEC" != "" && "$AUDIO_CODEC" != "unknown" ]]; then
        if [[ "$AUDIO_CODEC" == $COMPATIBLE_AUDIO && "$AUDIO_CHANNELS" == "2" ]]; then
            echo "  Audio codec '$AUDIO_CODEC' with $AUDIO_CHANNELS channels is compatible. Copying audio."
            AUDIO_PARAM="-c:a copy"
        elif [[ "$AUDIO_CODEC" == $COMPATIBLE_AUDIO && "$AUDIO_CHANNELS" != "2" ]]; then
            echo "  Audio codec '$AUDIO_CODEC' is compatible but has $AUDIO_CHANNELS channels. Re-encoding to stereo."
            # Re-encode to stereo while keeping AAC
            AUDIO_PARAM="-c:a aac -b:a 192k -ac 2"
            # Optional: Add an audio stream selection map to ensure we pick the right one
            AUDIO_PARAM="$AUDIO_PARAM -map 0:a:0"
        else
            echo "  Audio codec '$AUDIO_CODEC' is INCOMPATIBLE. Re-encoding audio to AAC (192k, stereo)."
            # Re-encode to AAC and set a reasonable bitrate, downmix to stereo
            AUDIO_PARAM="-c:a aac -b:a 192k -ac 2"
            # Optional: Add an audio stream selection map to ensure we pick the right one
            AUDIO_PARAM="$AUDIO_PARAM -map 0:a:0" 
        fi
    else
        echo "  No audio stream found or codec unknown. Assuming video-only or will rely on -c copy."
    fi

    echo "Outputting: ${OUTPUT_FILE}"

    # 3. The core FFmpeg command
    # -i: Input file
    # -map 0: Includes all streams (video, all audio, all subtitles)
    # -c copy: Instructs FFmpeg to copy the streams instead of re-encoding (fast/lossless remuxing)
    # If a stream is not MP4-compatible (e.g., DTS audio), you may need to re-encode it:
    # Example for incompatible audio: -c:v copy -c:a aac
    "${FFMPEG_CMD}" -i "${INPUT_FILE}" -map 0 -map -0:s ${VIDEO_COPY_PARAM} ${AUDIO_PARAM} "${OUTPUT_FILE}"

    # Check the exit status of FFmpeg
    if [[ $? -eq 0 ]]; then
        echo "SUCCESS: ${OUTPUT_FILE} created."
    else
        echo "ERROR: Failed to convert ${INPUT_FILE}."
    fi

    echo "---"
done

echo "Conversion process complete."
