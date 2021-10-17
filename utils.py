import phonenumbers

# TODO: test this
# Canonicalize US phone numbers
def format_tel(tel):
    num = phonenumbers.parse(tel, "US")
    if not phonenumbers.is_valid_number(num):
        return None
    return num.national_number

# ZSORTINGFIRSTNAME format from Apple contacts looks like
# [lowercased name] [actual name]
def clean_name(text):
    text = text.strip()
    for i in range(len(text)):
        if text[:i] in text.lower()[i:]:
            continue
        text = text[i:]
        break
    text = text.strip()

    return text
