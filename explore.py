import sqlite3
import pandas as pd
import os
import plistlib

from utils import format_tel

id_to_name = {}
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

# Parse address books
address_books = [
    "/Users/shekarramaswamy/Library/ApplicationSupport/AddressBook/Sources/58BDEBE3-DA9B-4BF3-A9CB-E5A17F4BC2CC/AddressBook-v22.abcddb",
    "/Users/shekarramaswamy/Library/ApplicationSupport/AddressBook/Sources/1675CD53-E9F2-46BF-9DE1-12EF837D05BB/AddressBook-v22.abcddb"
]

for a in address_books:
    cc = sqlite3.connect(a)
    cur = cc.cursor()

    # Name, ID
    cur.execute("select ZSORTINGFIRSTNAME, Z_PK from ZABCDRECORD order by Z_PK asc")
    for row in cur.fetchall():
        if row[0] is not None and row[1] is not None:
            # TODO: clean up first name
            id_to_name[row[1]] = row[0]

    # Phone number, ID
    cur.execute("select ZFULLNUMBER, ZOWNER from ZABCDPHONENUMBER order by ZOWNER asc")
    for row in cur.fetchall():
        if row[0] is not None and row[1] is not None:
            if row[1] in id_to_name:
                formatted_num = format_tel(row[0])
                if formatted_num is None:
                    # Log this
                    continue 
                num_to_name[format_tel(row[0])] = id_to_name[row[1]]
            else:
                # Log this
                pass
        else:
            print(row[1])

# Connect to chats database
conn = sqlite3.connect('/Users/shekarramaswamy/Library/Messages/chat.db')
cur = conn.cursor()
# get the names of the tables in the database
# cur.execute("select name from sqlite_master where type = 'table'") 
# for name in cur.fetchall():
    # print(name)

# cols = pd.read_sql_query("SELECT c.name FROM pragma_table_info('chat') c", conn)
# pd.set_option("display.max_rows", None, "display.max_columns", None)
# print(cols)

# messages = pd.read_sql_query("select text from message limit 10", conn)
# print(messages)
# print("-")

# From messages / chats / etc., I want to reconstruct the latest message history given the
# chat_identifier
num_to_messages = {}
cur.execute("""SELECT
    datetime (message.date / 1000000000 + strftime ("%s", "2001-01-01"), "unixepoch", "localtime") AS message_date,
    message.text,
    chat.chat_identifier
FROM
    chat
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
ORDER BY
    message_date DESC""")
for row in cur.fetchall():
    if row[2].startswith("chat") or "icloud" in row[2]: # skip group chat or icloud numbers
        continue
    formatted_num = format_tel(row[2])
    if formatted_num in num_to_messages:
        num_to_messages[formatted_num].append(row[1]) 
    else:
        num_to_messages[formatted_num] = [row[1]]

    
count = 0
for k in num_to_messages:
    if k in num_to_name:
        # print(num_to_name[k])
        pass
    else:
        print(k, num_to_messages[k])
        count += 1
        print(str(k) + " not found") # TODO: type k upstream
print(count)

######



# handles = pd.read_sql_query("select * from handle limit 10", conn)
# print(handles)
# print("-")

# chats = pd.read_sql_query("select * from chat limit 10", conn)
# print(chats)


# Other potentially interesting things
# https://docs.mau.fi/bridges/go/imessage/mac/setup.html
