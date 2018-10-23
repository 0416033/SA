#!/bin/sh
ls -AlR | sort -nrk 5 | awk 'BEGIN {dir=0;file=0;size=0;count=0} /^-/{file++;size+=$5;if(count<5)print $9,$5;count++} /^d/{dir++} END {print "File number = "file;print "Directory nuber = "dir;print "Total file size = "size}'
