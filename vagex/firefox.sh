#!/bin/bash
vncserver
rm -rf /root/.vnc/*.log
killall -9 firefox
export DISPLAY=:1;firefox
