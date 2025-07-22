# 🧰 Release XML Automation Tool

A Python-based automation tool for generating structured XML release files for database deployments. Designed to standardize and simplify release documentation across multiple client projects.

---

## 🚀 Features

- 🔄 **Auto-classifies SQL files** as Upgrade, Insert, Update, SP/Func, and Release Notes
- 🪜 **Custom execution order**: Upgrade → Insert → Update → SP/Func → Release Note (always last)
- 🔢 **Auto-increments version numbers** (e.g., `3.0000` → `3.0001`, ...)
- 📝 Generates well-formatted `release_output.xml` for deployment
- ✅ Supports dynamic release names and release note filenames
- 📊 Future-ready for Excel-based file input (configurable)

---

## 📂 Example Folder Structure

project/
├── generate_release.py
├── sql_files/
│ ├── Upgrade_InquiryDetails_1.3.sql
│ ├── Insert_SmartCareConfiguration_Kansas_538051.sql
│ ├── Update_ValidationRules.sql
│ ├── csp_SCVerifyElectronicEligibilityRequestData.sql
│ └── InsertScript_Coleman_BASE_6_0_0_12_000_2506_001.sql


---

## ⚙️ How It Works

1. Reads all `.sql` files from the `sql_files/` directory
2. Categorizes based on filename keywords:
   - `Upgrade` → Priority 1
   - `Insert` → Priority 2
   - `Update` → Priority 3
   - `SP/Func` → Priority 4
   - `InsertScript_*SEKMHC*` or `*BASE*` → Priority 99 (goes last)
3. Writes the sorted list into an XML with incremented version numbers

---

## 🧪 How to Run

```bash
# Step 1: Install Python 3.8+
# Step 2: Place SQL files in `sql_files/`
# Step 3: Run the script
python generate_release.py

Result → release_output.xml generated in the root directory.
🛠️ Tech Stack
Python 3.8+

os, xml.etree.ElementTree

(Optional) pandas if Excel support is added later

📈 Future Improvements
Read file types and priorities from Excel config

Add GUI or web upload interface

Support JSON/YAML-based release templates

Add validation for missing or duplicate scripts


🙋‍♂️ Author
Varun Sharma
BTech CSE - Health Informatics | VIT Bhopal | Streamline Healthcare Solutions
📍 Bangalore, India

