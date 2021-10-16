import phonenumbers

# TODO: test this
def format_tel(tel):
    num = phonenumbers.parse(tel, "US")
    if not phonenumbers.is_valid_number(num):
        return None
    return num.national_number
