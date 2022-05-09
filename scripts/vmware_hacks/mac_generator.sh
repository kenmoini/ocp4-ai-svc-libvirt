#!/bin/bash
# https://gist.github.com/tosin2013/eb9e67ab88da09b9597f1b7760f199c9

arr[0]="00:05:69:"
arr[1]="00:0c:29:"
arr[2]="00:1c:14:"
arr[3]="00:50:56:"

rand=$[$RANDOM % ${#arr[@]}]
end="$( echo $[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10]:$[RANDOM%10]$[RANDOM%10])"
echo "${arr[$rand]}$end"