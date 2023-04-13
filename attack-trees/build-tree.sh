#!/bin/bash
FILE=$1
if [ -f "${FILE}.dot" ]; then
  docker build -t graphviz-render .
	cat "${FILE}.dot" | docker run --rm -i graphviz-render > "${FILE}.png"
else 
    echo "${FILE}.dot does not exist."
fi