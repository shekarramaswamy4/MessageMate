import sqlite3
import pandas as pd
# substitute username with your username
conn = sqlite3.connect('/Users/shekarramaswamy/Library/Messages/chat.db')

# connect to the database
cur = conn.cursor()
# get the names of the tables in the database
# cur.execute("select name from sqlite_master where type = 'table'") 
# for name in cur.fetchall():
    # print(name)

cols = pd.read_sql_query("SELECT c.name FROM pragma_table_info('message') c", conn)
pd.set_option("display.max_rows", None, "display.max_columns", None)
print(cols)

messages = pd.read_sql_query("select text from message limit 10", conn)
print(messages)
print("-")

# From messages / chats / etc., I want to reconstruct the latest message history given the
# chat_identifier
messages = pd.read_sql_query("""SELECT
    chat.chat_identifier,
    count(chat.chat_identifier) AS message_count
FROM
    chat
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
GROUP BY
    chat.chat_identifier
ORDER BY
    message_count DESC;""", conn)
print(messages)

######
cc = sqlite3.connect("/Users/shekarramaswamy/Library/ApplicationSupport/AddressBook/Sources/58BDEBE3-DA9B-4BF3-A9CB-E5A17F4BC2CC/AddressBook-v22.abcddb")
tables = pd.read_sql_query("select name from sqlite_master where type='table'", cc)
print(tables)

# Gives name, ID
contacts = pd.read_sql_query("select ZSORTINGFIRSTNAME, Z_PK from ZABCDRECORD order by Z_PK asc limit 10", cc)
print(contacts)
print("-")

# Phone number, ID
contacts = pd.read_sql_query("select ZFULLNUMBER, ZOWNER from ZABCDPHONENUMBER order by ZOWNER asc limit 10", cc)
print(contacts)
print("-")



# handles = pd.read_sql_query("select * from handle limit 10", conn)
# print(handles)
# print("-")

# chats = pd.read_sql_query("select * from chat limit 10", conn)
# print(chats)


# Other potentially interesting things
# https://docs.mau.fi/bridges/go/imessage/mac/setup.html
