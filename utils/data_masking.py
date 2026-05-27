#!/usr/bin/env python3

import re

def mask_phone(phone):
    if not phone:
        return '\\N'
    phone = str(phone)
    if len(phone) == 11:
        return phone[:3] + '****' + phone[-4:]
    return '***'

def mask_email(email):
    if not email:
        return '\\N'
    email = str(email)
    match = re.match(r'^(.{2})(.*)(@.*)$', email)
    if match:
        return match.group(1) + '****' + match.group(3)
    return '***@***.com'

def mask_id_card(id_card):
    if not id_card:
        return '\\N'
    id_card = str(id_card)
    if len(id_card) == 18:
        return id_card[:4] + '**********' + id_card[-4:]
    return '******************'

def mask_address(address):
    if not address:
        return '\\N'
    address = str(address)
    if len(address) > 10:
        return address[:6] + '***'
    return address

def mask_field(value, field_type):
    field_type = field_type.lower()
    if 'phone' in field_type or 'tel' in field_type or 'mobile' in field_type:
        return mask_phone(value)
    elif 'email' in field_type:
        return mask_email(value)
    elif 'id_card' in field_type or 'idcard' in field_type:
        return mask_id_card(value)
    elif 'address' in field_type:
        return mask_address(value)
    elif 'password' in field_type or 'passwd' in field_type:
        return '******'
    else:
        return value

def mask_data(row, field_mask_map):
    masked_row = []
    for idx, value in enumerate(row):
        field_name = field_mask_map.get(idx, '')
        masked_row.append(mask_field(value, field_name))
    return masked_row

if __name__ == '__main__':
    test_data = [
        '13812345678',
        'user@example.com',
        '110101199001011234',
        '北京市朝阳区建国路88号',
        'password123'
    ]
    
    print("=== Data Masking Test ===")
    print(f"Phone: {mask_phone(test_data[0])}")
    print(f"Email: {mask_email(test_data[1])}")
    print(f"ID Card: {mask_id_card(test_data[2])}")
    print(f"Address: {mask_address(test_data[3])}")
    print(f"Password: {mask_field(test_data[4], 'password')}")