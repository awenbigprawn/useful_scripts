#!/usr/bin/env python3
import argparse
import os

DEFAULT_PATH = '/home/safebot/safebot/3dmap/deps/recorder/datasets/recorder_test_4cam'
DEFAULT_SEARCH = 'camera_0'
DEFAULT_REPLACE = 'camera_4'


def rename_files(path, search_string, replacement_string):
    for root, dirs, _files in os.walk(path):
        for dir_name in dirs:
            if search_string in dir_name:
                old_dir_path = os.path.join(root, dir_name)
                new_dir_name = dir_name.replace(search_string, replacement_string)
                new_dir_path = os.path.join(root, new_dir_name)
                os.rename(old_dir_path, new_dir_path)
                print(f'Renamed directory: {old_dir_path} -> {new_dir_path}')

    for root, _dirs, files in os.walk(path):
        for file_name in files:
            if search_string in file_name:
                old_file_path = os.path.join(root, file_name)
                new_file_name = file_name.replace(search_string, replacement_string)
                new_file_path = os.path.join(root, new_file_name)
                os.rename(old_file_path, new_file_path)
                print(f'Renamed file: {old_file_path} -> {new_file_path}')


def build_parser():
    parser = argparse.ArgumentParser(
        description='Rename directories and files by replacing a substring in their names.'
    )
    parser.add_argument(
        '--path',
        default=DEFAULT_PATH,
        help=f'Root directory to scan (default: {DEFAULT_PATH})',
    )
    parser.add_argument(
        '--search',
        default=DEFAULT_SEARCH,
        help=f'Substring to find in file and directory names (default: {DEFAULT_SEARCH})',
    )
    parser.add_argument(
        '--replace',
        default=DEFAULT_REPLACE,
        help=f'Replacement substring (default: {DEFAULT_REPLACE})',
    )
    return parser


def main():
    args = build_parser().parse_args()
    rename_files(args.path, args.search, args.replace)


if __name__ == '__main__':
    main()
