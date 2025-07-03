# import os
# import xml.etree.ElementTree as ET

# # CONFIGURATION - Make these variables customizable
# CONFIG = {
#     "release_name": "SEKMHC.BASE.6.0_0.03.000.2506.001",
#     "start_version": 3.0000,
#     "folder_path": "./sql_files",
#     "folder_name": "\\Database Objects",
#     "special_instructions_file": "",
#     "output_file": "release_output.xml"
# }

# # FUNCTION: PRIORITY + TYPE
# def get_priority_and_type(filename, release_name):
#     name = filename.lower()
    
#     # Create the expected release note pattern
#     # Convert release name to filename format (replace dots with underscores)
#     release_filename_format = release_name.replace(".", "_").lower()
#     release_pattern = f"insertscript_{release_filename_format}.sql"
    
#     # Check if this is the release note file
#     if name == release_pattern:
#         return (99, "Script")  # Release note always comes last
#     elif "upgrade" in name:
#         return (1, "DM")
#     elif "insert" in name:
#         return (2, "Script")
#     elif "update" in name:
#         return (3, "Script")
#     else:
#         return (4, "SP/Func")

# # STEP 1: COLLECT FILES
# all_files = []
# for filename in os.listdir(CONFIG["folder_path"]):
#     if filename.endswith(".sql"):
#         priority, file_type = get_priority_and_type(filename, CONFIG["release_name"])
#         all_files.append((priority, file_type, filename))

# # STEP 2: SORT FILES BASED ON PRIORITY
# all_files.sort(key=lambda x: x[0])

# # STEP 3: GENERATE XML
# release = ET.Element("release", {
#     "name": CONFIG["release_name"],
#     "StartVersion": f"{CONFIG['start_version']:.4f}",
#     "EndVersion": f"{CONFIG['start_version'] + len(all_files)*0.0001:.4f}",
#     "foldername": CONFIG["folder_name"],
#     "specialInstructionsFileName": CONFIG["special_instructions_file"]
# })

# files_tag = ET.SubElement(release, "files")
# current_version = CONFIG["start_version"]

# # STEP 4: ADD FILES TO XML
# for i, (_, file_type, filename) in enumerate(all_files, start=1):
#     upgrade_version = round(current_version + 0.0001, 4)
#     file_tag = ET.SubElement(files_tag, "file", {
#         "number": str(i),
#         "RDL": "No",
#         "Type": file_type
#     })
#     ET.SubElement(file_tag, "name").text = filename
#     ET.SubElement(file_tag, "current_version").text = f"{current_version:.4f}"
#     ET.SubElement(file_tag, "upgrade_version").text = f"{upgrade_version:.4f}"
#     current_version = upgrade_version

# # STEP 5: WRITE TO OUTPUT FILE
# ET.indent(release, space="  ")
# tree = ET.ElementTree(release)
# tree.write(CONFIG["output_file"], encoding="utf-8", xml_declaration=True)

# print(f"XML generated successfully: {CONFIG['output_file']}")
# print(f"Release note pattern: insertscript_{CONFIG['release_name'].replace('.', '_').lower()}.sql")

# # Optional: Print file processing summary
# print(f"\nProcessed {len(all_files)} files:")
# for priority, file_type, filename in all_files:
#     print(f"  Priority {priority} ({file_type}): {filename}")


import os
import xml.etree.ElementTree as ET

# CONFIGURATION 
release_name = "SEKMHC.BASE.6.0_0.03.000.2506.001"
start_version = 3.0000
folder_path = "./sql_files"  

def get_priority_and_type(filename, release_name):
    name = filename.lower()
    
    # Create the expected release note pattern
    # Convert release name to filename format (replace dots with underscores)
    release_filename_format = release_name.replace(".", "_").lower()
    release_pattern = f"insertscript_{release_filename_format}.sql"
    
    # Check if this is the release note file
    if name == release_pattern:
        return (99, "Script")  # Release note always comes last
    elif "upgrade" in name:
        return (1, "DM")
    elif "insert" in name:
        return (2, "Script")
    elif "update" in name:
        return (3, "Script")
    else:
        return (4, "SP/Func")

# def get_priority_and_type(filename):
#     name = filename.lower()
#     if "insertscript_sekmhc" in name:
#         return (99, "Script")  # as we keep the release note always at the end as per BRT priority sheet
#     elif "upgrade" in name:
#         return (1, "DM")
#     elif "insert" in name:
#         return (2, "Script")
#     elif "update" in name:
#         return (3, "Script")
#     else:
#         return (4, "SP/Func")

# OUR STEP 1 IS TO COLLECT FILES
all_files = []
for filename in os.listdir(folder_path):
    if filename.endswith(".sql"):
        priority, file_type = get_priority_and_type(filename, release_name)
        # priority, file_type = get_priority_and_type(filename)
        all_files.append((priority, file_type, filename))

# STEP 2 IS TO SORT FILES BASED ON PRIORITY
all_files.sort(key=lambda x: x[0])

# STEP 3 IS TO GENERATE XML
release = ET.Element("release", {
    "name": release_name,
    "StartVersion": f"{start_version:.4f}",
    "EndVersion": f"{start_version + len(all_files)*0.0001:.4f}",
    "foldername": "\\Database Objects",
    "specialInstructionsFileName": ""
})

files_tag = ET.SubElement(release, "files")
current_version = start_version

# STEP 4 IS TO ADD FILES TO XML
for i, (_, file_type, filename) in enumerate(all_files, start=1):
    upgrade_version = round(current_version + 0.0001, 4)
    file_tag = ET.SubElement(files_tag, "file", {
        "number": str(i),
        "RDL": "No",
        "Type": file_type
    })
    ET.SubElement(file_tag, "name").text = filename
    ET.SubElement(file_tag, "current_version").text = f"{current_version:.4f}"
    ET.SubElement(file_tag, "upgrade_version").text = f"{upgrade_version:.4f}"
    current_version = upgrade_version

# STEP 5: WRITE TO OUTPUT FILE
ET.indent(release, space="  ")
tree = ET.ElementTree(release)
tree.write("release_output.xml", encoding="utf-8", xml_declaration=True)

print("XML generated successfully")

