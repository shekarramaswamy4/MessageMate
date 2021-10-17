import sqlite3
import pandas as pd
from datetime import datetime
from typing import List

import utils

# Classes for better typing
class ContactMessageHistory:
    def __init__(self, phone_num, name, message_data):
        self.phone_num = phone_num
        self.name = name
        self.message_data = message_data

# Data on a single message. Expected to be part of a ContactMessageHistory class.
class MessageData:
    def __init__(self, pretty_date, timestamp, time_delta, text, is_from_me):
        self.pretty_date = pretty_date
        self.timestamp = timestamp
        self.time_delta = time_delta
        self.text = text
        self.is_from_me = is_from_me

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
                id_to_name[row[1]] = utils.clean_name(row[0])

        # Phone number, ID
        cur.execute("select ZFULLNUMBER, ZOWNER from ZABCDPHONENUMBER order by ZOWNER asc")
        for row in cur.fetchall():
            if row[0] is not None and row[1] is not None:
                if row[1] in id_to_name:
                    formatted_num = utils.format_tel(row[0])
                    if formatted_num is None:
                        # Log this
                        continue 
                    num_to_name[utils.format_tel(row[0])] = id_to_name[row[1]]
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

        formatted_num = utils.format_tel(row[2])
        if formatted_num not in num_to_name:
            continue

        unixtimestamp = datetime.fromisoformat(row[0]).timestamp()
        diff = now.timestamp() - unixtimestamp

        key = (formatted_num, num_to_name[formatted_num])
        data = MessageData(row[0], unixtimestamp, diff, row[1], row[3])
        if key in num_to_messages:
            num_to_messages[key].append(data) 
        else:
            num_to_messages[key] = [data]
    
    contact_messages = []
    for k in num_to_messages:
        cmh = ContactMessageHistory(k[0], k[1], num_to_messages[k])
        contact_messages.append(cmh)
    return contact_messages

# Suggest the person to text back if:
# - The last message(s) were from the other person
# - Messages are over a day old
# - Message was a question
# - Message was not an ack like "kk"
def run_suggestions(contact_messages: List[ContactMessageHistory]):
    for cm in contact_messages:
        if score_contact(cm) == 1:
            # TODO: add more data about the person
            print(cm.name)

# Recent burst defines the last set of messages from the contact that was sent
# recent_burst is guaranteed to be the chronologically descending, last set of messages
# sent from the contact
# it is also guaranteed to have at least one element
def get_recent_burst(cm: ContactMessageHistory):
    if len(cm.message_data) == 0:
        return []
    if cm.message_data[0].is_from_me == 1:
        return []

    recent_burst = []
    for c in cm.message_data:
        if c.is_from_me == 1:
            break
        recent_burst.append(c)
    return recent_burst

# Returns 0 if the contact shouldn't be suggested
# Returns >0 if the contact should be suggested. Higher value means a better suggestion
def score_contact(cm: ContactMessageHistory):
    # Note: be careful for c.text = None (likely an attachment)
    recent_burst = get_recent_burst(cm)
    if len(recent_burst) == 0:
        return 0

    # check if recent_burst occurred over a day ago
    if recent_burst[0].time_delta < 86400:
        return 0

    # if more than one message, suggest
    if len(recent_burst) > 1:
        return 1
    
    last_message = recent_burst[0]
    if not last_message.text:
        return 0

    t = last_message.text.lower()
    if "?" in t:
        return 1
    if "loved" in t or "liked" in t or "emphasized" in t: # Reactions
        return 0
    if len(t) < 4:
        return 0
    if "thank" in t or "sounds good" in t:
        return 0

    return 1

# Open system preferences: open "x-apple.systempreferences:com.apple.preference.security?Privacy"
# Send notifications via apple script: osascript -e 'display notification "hello world!" with title "Greeting" subtitle "More text" sound name "Submarine"'

data = fetch_and_format_message_data()
run_suggestions(data)

# Other potentially interesting things
# https://docs.mau.fi/bridges/go/imessage/mac/setup.html
