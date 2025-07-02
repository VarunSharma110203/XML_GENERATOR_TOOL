import os
import xml.etree.ElementTree as ET

# CONFIGURATION 
release_name = "SEKMHC.BASE.6.0_0.03.000.2506.001"
start_version = 3.0000
folder_path = "./sql_files"  

# FUNCTION: PRIORITY + TYPE 
def get_priority_and_type(filename):
    name = filename.lower()
    if "insertscript_sekmhc" in name:
        return (99, "Script")  # as we keep the release note always at the end as per BRT priority sheet
    elif "upgrade" in name:
        return (1, "DM")
    elif "insert" in name:
        return (2, "Script")
    elif "update" in name:
        return (3, "Script")
    else:
        return (4, "SP/Func")

# OUR STEP 1 IS TO COLLECT FILES
all_files = []
for filename in os.listdir(folder_path):
    if filename.endswith(".sql"):
        priority, file_type = get_priority_and_type(filename)
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

print("✅ XML generated successfully as 'release_output.xml'")

