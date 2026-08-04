import os
import subprocess
import re
import xml.etree.ElementTree as ET

def main():
    os.makedirs("assets/romfs/haxe3ds", exist_ok=True)
    with open("assets/romfs/haxe3ds/version", "w") as f:
        f.write("")

    if not os.path.exists("assets"):
        print("No 'assets' directory found. Skipping conversion.")
        return

    for root, dirs, files in os.walk("assets"):
        for file in files:
            file_path = os.path.join(root, file)
            name, ext = os.path.splitext(file)
            ext = ext.lower()

            if ext == ".png":
                out_path = os.path.join(root, name + ".t3x")
                print(f"Converting {file_path} to T3X...")
                subprocess.run(["tex3ds", "-i", file_path, "-o", out_path], check=True)

            elif ext == ".xml":
                out_path = os.path.join(root, name + ".cea")
                print(f"Converting {file_path} to CEA...")
                try:
                    tree = ET.parse(file_path)
                    xml_root = tree.getroot()
                    lines = []
                    
                    for sub in xml_root.findall('SubTexture'):
                        sub_name = sub.get('name')
                        frameX = sub.get('frameX', '0')
                        frameY = sub.get('frameY', '0')
                        
                        match = re.match(r'^(.*?)([0-9]+)$', sub_name)
                        anim_name = match.group(1) if match else sub_name
                        
                        lines.append(f"{sub_name}?{frameX}?{frameY}?{anim_name}")
                        
                    with open(out_path, "w", encoding="utf-8") as f:
                        f.write("\n".join(lines))
                except Exception as e:
                    print(f"Error parsing {file_path}: {e}")

            elif ext == ".mp3":
                out_path = os.path.join(root, name + ".ogg")
                print(f"Converting {file_path} to OGG...")
                subprocess.run(["ffmpeg", "-y", "-i", file_path, "-q:a", "4", out_path], check=True)
                os.remove(file_path)

            elif ext == ".ogg":
                out_path = os.path.join(root, name + ".cwav")
                print(f"Converting {file_path} to CWAV...")
                subprocess.run(["cwavtool", "-i", file_path, "-o", out_path], check=True)

if __name__ == "__main__":
    main()
