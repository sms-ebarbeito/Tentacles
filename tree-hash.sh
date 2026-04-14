#!/bin/bash
find . -not -path './.build/*' -not -path './.git/*' | sort | while read f; do
	indent=$(echo "$f" | awk -F'/' '{for(i=2;i<NF;i++) printf " "; if(NF>1) printf ""}')
	name=$(basename "$f")
	if [ -f "$f" ]; then
		hash=$(md5 -q "$f")
		echo "${indent}${name} [${hash}]"
	else
		echo "${indent}${name}/"
	fi
done
