"""@bruin
name: upload_to_gcs
type: python
@bruin"""

import subprocess
import os
import sys

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
    script_path = os.path.join(os.path.dirname(__file__), "upload_to_gcs.sh")
    
    cmd = ["bash", script_path]
    
    if os.environ.get("BRUIN_FULL_REFRESH") == "1":
        print("Running with --force due to full refresh.")
        #cmd.append("--force")

    print(f"Executing: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=root_dir)
    
    if result.returncode != 0:
        print("Upload failed.")
        sys.exit(result.returncode)

if __name__ == "__main__":
    main()
