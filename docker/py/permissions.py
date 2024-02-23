#!/usr/bin/env python3
import os
import argparse
from tqdm import tqdm

# Python is lightning fast compared to bash for changing files and directories
def update_permissions(root_path, dir_perm=0o755, file_perm=0o644):
    # Collect all paths
    paths = []
    for root, dirs, files in os.walk(root_path):
        for d in dirs:
            paths.append(os.path.join(root, d))
        for f in files:
            paths.append(os.path.join(root, f))

    print("Total paths to process:", len(paths))

    # Create a progress bar
    with tqdm(total=len(paths), desc="Updating Permissions") as pbar:
        for path in paths:
            # print("Processing:", path)
            if os.path.isdir(path):
                os.chmod(path, dir_perm)
            elif os.path.isfile(path):
                os.chmod(path, file_perm)
            pbar.update(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Update permissions of files and directories.')
    parser.add_argument('path', type=str, help='The root path for updating permissions')
    args = parser.parse_args()
    print("Updating permissions for path: {}".format(args.path))
    update_permissions(args.path)
