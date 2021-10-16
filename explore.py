import sqlite3
import pandas as pd
from utils import format_tel

# Connect to contacts
cc = sqlite3.connect("/Users/shekarramaswamy/Library/ApplicationSupport/AddressBook/Sources/58BDEBE3-DA9B-4BF3-A9CB-E5A17F4BC2CC/AddressBook-v22.abcddb")
# tables = pd.read_sql_query("select name from sqlite_master where type='table'", cc)
# print(tables)
cur = cc.cursor()

# Gives name, ID
id_to_name = {}
cur.execute("select ZSORTINGFIRSTNAME, Z_PK from ZABCDRECORD order by Z_PK asc")
for row in cur.fetchall():
    if row[0] is not None and row[1] is not None:
        # TODO: clean up first name
        id_to_name[row[1]] = row[0]

# Phone number, ID
num_to_name = {}
cur.execute("select ZFULLNUMBER, ZOWNER from ZABCDPHONENUMBER order by ZOWNER asc")
for row in cur.fetchall():
    if row[0] is not None and row[1] is not None:
        if row[1] in id_to_name:
            formatted_num = format_tel(row[0])
            if formatted_num is None:
                # Log this
                break
            num_to_name[format_tel(row[0])] = id_to_name[row[1]]
        else:
            # Log this
            pass

print(num_to_name)
# substitute username with your username
conn = sqlite3.connect('/Users/shekarramaswamy/Library/Messages/chat.db')

# connect to the database
cur = conn.cursor()
# get the names of the tables in the database
# cur.execute("select name from sqlite_master where type = 'table'") 
# for name in cur.fetchall():
    # print(name)

cols = pd.read_sql_query("SELECT c.name FROM pragma_table_info('chat') c", conn)
pd.set_option("display.max_rows", None, "display.max_columns", None)
print(cols)

# messages = pd.read_sql_query("select text from message limit 10", conn)
# print(messages)
# print("-")

# From messages / chats / etc., I want to reconstruct the latest message history given the
# chat_identifier
messages = pd.read_sql_query("""SELECT
    datetime (message.date / 1000000000 + strftime ("%s", "2001-01-01"), "unixepoch", "localtime") AS message_date,
    message.text,
    chat.chat_identifier
FROM
    chat
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
ORDER BY
    message_date DESC 
LIMIT 10;""", conn)
print(messages)

######



# handles = pd.read_sql_query("select * from handle limit 10", conn)
# print(handles)
# print("-")

# chats = pd.read_sql_query("select * from chat limit 10", conn)
# print(chats)


# Other potentially interesting things
# https://docs.mau.fi/bridges/go/imessage/mac/setup.html
