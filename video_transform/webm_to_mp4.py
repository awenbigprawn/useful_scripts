#!/usr/bin/env python3
import argparse

DEFAULT_INPUT = 'demo_with_occupancymap.webm'
DEFAULT_OUTPUT = 'demo_with_occupancymap.mp4'


def convert_webm_to_mp4(input_path, output_path):
    try:
        from moviepy import VideoFileClip

        clip = VideoFileClip(input_path)
        clip.write_videofile(output_path, codec='libx264', audio_codec='aac')
        clip.close()
        print(f'Conversion successful! Saved to {output_path}')
    except Exception as exc:
        print(f'Error during conversion: {exc}')


def build_parser():
    parser = argparse.ArgumentParser(
        description='Convert a WebM video file to MP4 using moviepy and ffmpeg.'
    )
    parser.add_argument(
        'input_file',
        nargs='?',
        default=DEFAULT_INPUT,
        help=f'Input .webm file (default: {DEFAULT_INPUT})',
    )
    parser.add_argument(
        'output_file',
        nargs='?',
        default=DEFAULT_OUTPUT,
        help=f'Output .mp4 file (default: {DEFAULT_OUTPUT})',
    )
    return parser


def main():
    args = build_parser().parse_args()
    convert_webm_to_mp4(args.input_file, args.output_file)


if __name__ == '__main__':
    main()
