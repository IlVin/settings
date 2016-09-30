#!/bin/bash

modprobe zram num_devices=1
echo $( 16 * 1024 * 1024 * 1024) > /sys/block/zram0/disksize
