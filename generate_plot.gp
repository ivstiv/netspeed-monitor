#!/usr/local/bin/gnuplot --persist

print "Log file: ", ARG1
print "Title: ", ARG2
print "Output: ", ARG3

set title ARG2
set xdata time
set timefmt '%H:%M'
set format x '%H:%M'
set terminal png linewidth 2 size 2000,640
set output ARG3
set samples 1000

plot ARG1 using 1:2 smooth cspline title 'Download Mbps', ARG1 using 1:3 smooth cspline title 'Upload Mbps'
#plot ARG1 using 1:2 pt 7 ps 1 title 'Download Mbps', ARG1 using 1:3 pt 7 ps 1 title 'Upload Mbps'