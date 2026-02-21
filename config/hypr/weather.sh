#!/usr/bin/env bash
# Author: Lokesh Mohanty
# Usage: sh weather.sh

while true; do
		curl wttr.in
    read -r -n 1 -s input
    if [[ $input = "q" ]] || [[ $input = "Q" ]] 
        then break 
    fi
done
