: "
name: project_tree
description: Generates a JSON representation of the directory structure for a given path and depth.
parameters: $1=目录路径, $2=最大层级(default: 3)
"
DIR="${1:-.}"
DEPTH="${2:-3}"

echo "{\"tree\": ["
first=1
while IFS= read -r path; do
    level=$(echo "$path" | tr -cd '/' | wc -c)
    name=$(basename "$path")
    [ -d "$path" ] && type="dir" || type="file"
    if [ $first -eq 1 ]; then
        first=0
    else
        echo ","
    fi
    printf "{\"name\":\"%s\",\"type\":\"%s\",\"depth\":%d}" "$name" "$type" "$level"
done < <(find "$DIR" -maxdepth "$DEPTH" -not -path '*/\\.*' -not -path '*/node_modules/*' | sort)
echo ""
echo "]}"