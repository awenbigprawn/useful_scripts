from moviepy import VideoFileClip

def convert_webm_to_mp4(input_path, output_path):
    try:
        clip = VideoFileClip(input_path)
        clip.write_videofile(output_path, codec='libx264', audio_codec='aac')
        print(f"Conversion successful! Saved to {output_path}")
    except Exception as e:
        print(f"Error during conversion: {e}")

# Example usage:
if __name__ == "__main__":
    input_file = "demo_with_occupancymap.webm"
    output_file = "demo_with_occupancymap.mp4"
    convert_webm_to_mp4(input_file, output_file)
