import phonenumbers

# TODO: test this
# Canonicalize US phone numbers
def format_tel(tel):
    try:
        num = phonenumbers.parse(tel, "US")
    except:
        return None
    if not phonenumbers.is_valid_number(num):
        return None
    return num.national_number

# TODO: test this
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
