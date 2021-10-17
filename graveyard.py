import os
import plistlib

from utils import format_tel

### OLD CODE ###

num_to_name = {}

# Going to parse abcdp files first and add to dictionary
abcdp_dirs = [
    "/Users/shekarramaswamy/Library/ApplicationSupport/AddressBook/Sources/58BDEBE3-DA9B-4BF3-A9CB-E5A17F4BC2CC/Metadata"
]
for cdir in abcdp_dirs:
    mkdir_cmd = "mkdir " + cdir + "/tmp"
    cp_cmd = "cp " + cdir + "/*.abcdp " + cdir + "/tmp"
    rm_cmd = "rm -rf " + cdir + "/tmp"

    os.system(mkdir_cmd)
    os.system(cp_cmd)
    count = 0
    for filename in os.listdir(cdir + "/tmp/"):
        full_path = os.path.join(cdir +"/tmp/", filename)
        os.system("plutil -convert xml1 " + full_path) # Prepare file to be read in xml

        f = open(full_path)
        data = bytes(f.read(), 'utf-8')

        try:
            parsed = plistlib.loads(data)
            first = parsed["First"]
            last = parsed["Last"] if "Last" in parsed else ""
            number = parsed["Phone"]["values"][0]

            formatted_num = format_tel(number)
            if formatted_num is None:
                continue
            num_to_name[number] = first + " " + last
        except:
            pass
            # Log this

    os.system(rm_cmd)

