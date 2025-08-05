import os

def rename_files(path, search_string, replacement_string):
    for root, dirs, files in os.walk(path):
        for dir_name in dirs:
            if search_string in dir_name:
                old_dir_path = os.path.join(root, dir_name)
                new_dir_name = dir_name.replace(search_string, replacement_string)
                new_dir_path = os.path.join(root, new_dir_name)
                os.rename(old_dir_path, new_dir_path)
                print(f'Renamed directory: {old_dir_path} -> {new_dir_path}')
    for root, dirs, files in os.walk(path):
        for file in files:
            if 'camera_0' in file:
                old_file_path = os.path.join(root, file)
                new_file_name = file.replace(search_string, replacement_string)
                new_file_path = os.path.join(root, new_file_name)
                os.rename(old_file_path, new_file_path)
                print(f'Renamed: {old_file_path} -> {new_file_path}')

rename_files('/home/safebot/safebot/3dmap/deps/recorder/datasets/recorder_test_4cam',
             search_string="camera_0",
             replacement_string="camera_4")
