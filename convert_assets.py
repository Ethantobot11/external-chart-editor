import os
import subprocess
import re
import xml.etree.ElementTree as ET
from PIL import Image

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
                print(f"Processing and converting {file_path} to T3X...")
                
                try:
                    with Image.open(file_path) as img:
                        img = img.convert("RGBA")
                        width, height = img.size
                        
                        new_width = (width + 3) & ~3
                        new_height = (height + 3) & ~3
                        
                        if new_width != width or new_height != height:
                            print(f"Resizing {file_path} from {width}x{height} to {new_width}x{new_height}.")
                            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                        
                        img.save(file_path, "PNG")
                except Exception as e:
                    print(f"Warning: Could not process image {file_path}: {e}")

                abs_input = os.path.abspath(file_path)
                abs_output = os.path.abspath(out_path)
                
                try:
                    subprocess.run(["tex3ds", "-f", "RGBA8", "-i", abs_input, "-o", abs_output], check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error: tex3ds failed on {file_path} (Exit code {e.returncode}).")

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
                    print(f"Error parsing XML file {file_path}: {e}. Skipping...")

            elif ext == ".mp3":
                out_path = os.path.join(root, name + ".ogg")
                print(f"Converting {file_path} to OGG...")
                try:
                    subprocess.run(["ffmpeg", "-y", "-i", file_path, "-q:a", "4", out_path], check=True)
                    if os.path.exists(file_path):
                        os.remove(file_path)
                except subprocess.CalledProcessError as e:
                    print(f"Error: ffmpeg failed to convert {file_path} (Exit code {e.returncode}). Skipping...")
                except Exception as e:
                    print(f"Unexpected error during MP3 conversion for {file_path}: {e}")

            elif ext == ".ogg":
                out_path = os.path.join(root, name + ".cwav")
                print(f"Converting {file_path} to CWAV...")
                try:
                    subprocess.run(["cwavtool", "-i", file_path, "-o", out_path], check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error: cwavtool failed on {file_path} (Exit code {e.returncode}). Skipping...")
                except Exception as e:
                    print(f"Unexpected error during CWAV conversion for {file_path}: {e}")

if __name__ == "__main__":
    main()
