#!/bin/sh
set -e

mkdir -p assets/romfs/haxe3ds
touch assets/romfs/haxe3ds/version

export PATH=/opt/devkitpro/tools/bin:$PATH

if [ -d "assets" ]; then
    for file in $(find assets/ -type f -name "*.png"); do
        dir=$(dirname "$file")
        filename=$(basename "$file")
        nameonly="${filename%.*}"
        
        echo "Converting $file to T3X..."
        tex3ds -i "$file" -o "${dir}/${nameonly}.t3x"
    done

    for xmlfile in $(find assets/ -type f -name "*.xml"); do
        dir=$(dirname "$xmlfile")
        filename=$(basename "$xmlfile")
        nameonly="${filename%.*}"
        ceafile="${dir}/${nameonly}.cea"
        
        echo "Converting $xmlfile to $ceafile..."
        python3 - <<EOF
import xml.etree.ElementTree as ET
import re

try:
    tree = ET.parse('$xmlfile')
    root = tree.getroot()
    lines = []
    
    for sub in root.findall('SubTexture'):
        name = sub.get('name')
        frameX = sub.get('frameX', '0')
        frameY = sub.get('frameY', '0')
        
        match = re.match(r'^(.*?)([0-9]+)$', name)
        anim_name = match.group(1) if match else name
        
        lines.append(f'{name}?{frameX}?{frameY}?{anim_name}')
        
    with open('$ceafile', 'w') as f:
        f.write('\n'.join(lines))
except Exception as e:
    print(f"Error parsing $xmlfile: {e}")
EOF
    done

    for file in $(find assets/ -type f -name "*.mp3"); do
        dir=$(dirname "$file")
        filename=$(basename "$file")
        nameonly="${filename%.*}"
        ffmpeg -y -i "$file" -q:a 4 "${dir}/${nameonly}.ogg"
        rm "$file"
    done

    for file in $(find assets/ -type f -name "*.ogg"); do
        dir=$(dirname "$file")
        filename=$(basename "$file")
        nameonly="${filename%.*}"
        
        echo "Converting $file to CWAV..."
        cwavtool -i "$file" -o "${dir}/${nameonly}.cwav"
    done
fi