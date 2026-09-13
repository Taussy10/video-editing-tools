import argparse
import os
from pydub import AudioSegment
from pydub.silence import split_on_silence

def remove_silence(input_path, output_path, min_silence_len=500, silence_thresh=-40, keep_silence=150):
    print(f"Processing: {input_path}")
    
    # Load audio
    try:
        audio = AudioSegment.from_file(input_path)
    except Exception as e:
        print(f"Error loading audio: {e}")
        print("Note: Working with some files requires 'ffmpeg' installed on your system.")
        return False

    print("Detecting silence...")
    # Split audio on silence
    # min_silence_len: minimum length of silence in ms to be considered as silence
    # silence_thresh: silence threshold in dBFS (decibels relative to full scale)
    # keep_silence: leave some silence at the beginning/end of the chunks (makes it sound more natural)
    chunks = split_on_silence(
        audio,
        min_silence_len=min_silence_len,
        silence_thresh=silence_thresh,
        keep_silence=keep_silence 
    )
    
    if not chunks:
        print("No non-silent chunks found. The audio might be entirely silent or the threshold is too high.")
        return False
        
    print(f"Found {len(chunks)} non-silent chunks. Combining...")
    
    # Combine chunks
    combined = AudioSegment.empty()
    for chunk in chunks:
        combined += chunk
        
    # Export
    print(f"Exporting to: {output_path}")
    export_format = output_path.split('.')[-1].lower()
    if export_format not in ['wav', 'mp3', 'ogg', 'flac', 'm4a', 'mp4']:
        export_format = 'mp3'
    if export_format == 'm4a':
        export_format = 'ipod' # pydub specific format for m4a

    try:
        combined.export(output_path, format=export_format)
    except Exception as e:
        print(f"Export error: {e}. You may need to install ffmpeg.")
        return False
    print("Done!")
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove silence from audio.")
    parser.add_argument("input", help="Path to input audio file")
    parser.add_argument("output", help="Path to output audio file")
    parser.add_argument("--min_silence", type=int, default=500, help="Minimum silence length in ms (default: 500)")
    parser.add_argument("--threshold", type=int, default=-40, help="Silence threshold in dBFS (default: -40)")
    parser.add_argument("--keep_silence", type=int, default=150, help="Amount of silence to keep at edges in ms (default: 150)")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"Input file not found: {args.input}")
        exit(1)
    else:
        success = remove_silence(args.input, args.output, args.min_silence, args.threshold, args.keep_silence)
        if not success:
            exit(1)
