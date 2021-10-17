import sqlite3
import pandas as pd
from datetime import datetime

from utils import format_tel, clean_name

def fetch_and_format_message_data():
    id_to_name = {}
    num_to_name = {}

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
                id_to_name[row[1]] = clean_name(row[0])

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
                # Log this
                pass

    # Connect to chats database
    conn = sqlite3.connect('/Users/shekarramaswamy/Library/Messages/chat.db')
    cur = conn.cursor()
    
    now = datetime.now()

    num_to_messages = {}
    cur.execute("""SELECT
        datetime (message.date / 1000000000 + strftime ("%s", "2001-01-01"), "unixepoch", "localtime") AS message_date,
        message.text,
        chat.chat_identifier,
        message.is_from_me
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
        if formatted_num not in num_to_name:
            continue

        unixtimestamp = datetime.fromisoformat(row[0]).timestamp()
        diff = now.timestamp() - unixtimestamp

        key = (formatted_num, num_to_name[formatted_num])
        obj = (row[0], unixtimestamp, diff, row[1], row[3]) 
        if key in num_to_messages:
            num_to_messages[key].append(obj) 
        else:
            num_to_messages[key] = [obj]
    
    return num_to_messages

# Suggest the person to text back if:
# - The last message(s) were from the other person
# - Messages are over a day old
# - Message was a question
# - Message was not an ack like "kk"
def run_suggestions(data):
    for d in data:
        if score_contact(d, data[d]) == 1:
            print(d)

def score_contact(key, chats):
    for c in chats:
        if c[2] < 86400:
            return 0
    return 1

# Send notifications via apple script: osascript -e 'display notification "hello world!" with title "Greeting" subtitle "More text" sound name "Submarine"'

data = fetch_and_format_message_data()
run_suggestions(data)

# Other potentially interesting things
# https://docs.mau.fi/bridges/go/imessage/mac/setup.html
