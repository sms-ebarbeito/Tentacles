---
name: tree-hash.sh utility
description: Bash script in repo root that prints file tree with md5 hashes beside each file
type: project
---

`tree-hash.sh` lives at the repo root. Run with `./tree-hash.sh`.

Shows a tree of all files with their md5 hash in brackets, excluding `.build/` and `.git/`. Uses `md5 -q` (macOS). User asked for it "super chiquita" (minimal).

```bash
find . -not -path './.build/*' -not -path './.git/*' | sort | while read f; do
    indent=$(echo "$f" | awk -F'/' '{for(i=2;i<NF;i++) printf "  "; if(NF>1) printf ""}')
    name=$(basename "$f")
    if [ -f "$f" ]; then
        hash=$(md5 -q "$f")
        echo "${indent}${name}  [${hash}]"
    else
        echo "${indent}${name}/"
    fi
done
```
