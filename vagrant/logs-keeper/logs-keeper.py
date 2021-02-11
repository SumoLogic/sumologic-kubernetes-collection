#!/usr/bin/env python3
"""
Log keeper follow all symlinks in given directory and creates hardlinks to prevent lost data during file rotation
Usage:

KEEP_TIME=3600 ./logs-keeper <directory_path>
"""

import logging
import os
import shutil
import sys
import time

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
log = logging.getLogger()
KEEP_TIME = int(os.getenv("KEEP_TIME_S", 120))

def main(monitor_directory):
    while True:
        files = [
            os.path.abspath(os.path.join(monitor_directory, f))
                for f in os.listdir(monitor_directory)
                    if os.path.isfile(os.path.join(monitor_directory, f))
                ]
        for file_path in files:
            fm = FileMonitor(file_path)
            fm.link_file()

            fm.expire_files()
        
        sumo_dir = os.path.join(monitor_directory, 'sumologic')
        if not os.path.isdir(sumo_dir):
            os.mkdir(sumo_dir)
        inodes = os.listdir(sumo_dir)
        for inode in inodes:
            file = os.listdir(os.path.join(sumo_dir, inode))[0]
            path = os.readlink(os.path.join(sumo_dir, inode, file))

            if not os.path.isfile(path):
                log.info(f'Removing symlink to non-existing file: {inode}')
                shutil.rmtree(os.path.join(sumo_dir, inode))

        time.sleep(0.2)


class FileMonitor:
    def __init__(self, file_path):
        self._file_path = file_path
        self.filename = os.path.basename(self._file_path)
    
    @property
    def dst_path(self):
        return_value = self._file_path
        return_value_dirname = os.path.dirname(return_value)
        while os.path.islink(return_value):
            return_value = os.readlink(return_value)
    
            # Get abspath of the link
            if os.path.abspath(return_value) != return_value:
                return_value = os.path.abspath(os.path.join(return_value_dirname, return_value))

            return_value_dirname = os.path.dirname(return_value)

        return return_value
    
    @property
    def dst_dirname(self):
        return os.path.dirname(self.dst_path)
    
    @property
    def dst_sumo_dir(self):
        return os.path.join(self.dst_dirname, 'sumologic')
    
    @property
    def dst_inode_dir(self):
        return self.get_dst_inode_dir(str(self.inode))
    
    def dst_timestamp_dir(self):
        return os.path.join(self.dst_inode_dir, str(int(time.time())))
    
    @property
    def src_dirname(self):
        return os.path.dirname(self._file_path)

    @property
    def src_sumo_dir(self):
        return os.path.join(self.src_dirname, 'sumologic')

    @property
    def src_inode_dir(self):
        return self.get_src_inode_dir(str(self.inode))
    
    def get_dst_inode_dir(self, inode):
        return os.path.join(self.dst_sumo_dir, inode)

    def get_src_inode_dir(self, inode):
        return os.path.join(self.src_sumo_dir, inode)
    
    @property
    def inode(self):
        return os.stat(self.dst_path, follow_symlinks=True).st_ino
    
    def link_file(self):
        """
        self.file_path -> dirname(self.file_path)/sumologic/<inode>/<timestamp>/basename(self.file_path)

        Takes real path of the file (following symlinks) and create hardlink in subdirectory to it
        """
        if os.path.isdir(self.dst_inode_dir):
            # Skip already linked file
            return

        # Create hard link for inode
        log.info(f'Creating link for {self.inode}:{self.filename}')
        ts_dir = self.dst_timestamp_dir()
        os.makedirs(ts_dir, exist_ok=True)
        hardlink = os.path.join(ts_dir, self.filename)
        os.link(self.dst_path, hardlink)

        # Create symbolic link to hardlink
        os.makedirs(self.src_inode_dir)
        symlink = os.path.join(self.src_inode_dir, self.filename)
        os.symlink(hardlink, symlink)
    
    def expire_files(self):
        """
        Scan for files which already expired and remove them
        """
        # 1. Get all subdirectories names (inodes) from sumologic directory
        try:
            inodes = os.listdir(self.dst_sumo_dir)
        except:
            log.info(f'{self.dst_sumo_dir} doesn\'t exist')
            return

        # 2. For every inode check creation time (subdirectory name) and remove if it exists longer than KEEP_TIME
        for inode in inodes:
            if int(inode) == self.inode:
                # Skip not rotated file
                # ToDo: update not rotated inode timestamp
                log.debug(f'Skipping not rotated file: {inode}')
                continue

            current = self.get_dst_inode_dir(inode)

            # FixMe: Check if still needed
            try:
                timestamp = int(os.listdir(current)[0])
            except:
                timestamp = 0

            if timestamp + KEEP_TIME < time.time():
                log.info(f'Removing {inode}')
                try:
                    shutil.rmtree(current)
                except FileNotFoundError:
                    pass

                try:
                    shutil.rmtree(self.get_src_inode_dir(inode))
                except FileNotFoundError:
                    pass

if __name__ == '__main__':
    main(os.path.realpath(sys.argv[1]))
