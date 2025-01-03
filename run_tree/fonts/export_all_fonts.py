import os
import subprocess

# Specify the .bat file to execute
bat_file = "gen_font_sdf.bat"  # Update this with the actual .bat filename

if not os.path.exists(bat_file):
    print(f"Error: '{bat_file}' does not exist in the current directory.")
    exit(1)

# Get all .ttf files in the current directory
ttf_files = [f.replace(".ttf","") for f in os.listdir('.') if f.endswith('.ttf')]

if not ttf_files:
    print("No .ttf files found in the current directory.")
else:
    print(f"Found {len(ttf_files)} .ttf files.")

# Run the .bat file on each .ttf file
for ttf_file in ttf_files:
    try:
        print(f"Processing '{ttf_file}'...")
        subprocess.run([bat_file, ttf_file], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error processing '{ttf_file}': {e}")

print("Done.")
