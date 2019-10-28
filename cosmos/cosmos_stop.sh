#!/bin/bash
  
ps -ef | grep gaiad | grep -v grep | awk '{print $2}' | xargs -i kill -9 {}
