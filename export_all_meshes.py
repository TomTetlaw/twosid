import bpy
import os
import sys

if __name__ == "__main__":
    source_directory = sys.argv[-2]
    dest_directory = sys.argv[-1]
    
    print("\nBATCH MESH EXPORTER")
    print("source = " + source_directory)
    print("dest = " + dest_directory)
    
    print("\nBLEND FILES:")
    blend_files = [f for f in os.listdir(source_directory) if f.endswith('.blend')]
    for file in blend_files:
        print(file)
        
    print("\nMESH FILES:")
    for file in blend_files:
        mesh_name = file.split(".")[0]
        output_filename = dest_directory + "/" + mesh_name + ".mesh"
        print(output_filename)
    print("\nBLENDER OUTPUT:")
    for file in blend_files:
        blend_file_path = os.path.join(source_directory, file)
        
        mesh_name = file.split(".")[0]
        output_filename = dest_directory + "/" + mesh_name + ".mesh"
        
        bpy.ops.wm.open_mainfile(filepath = blend_file_path)
        bpy.ops.export.project_skeleton_mesh(filepath=output_filename)
        
    print("FINISHED")