#!/usr/bin/env python3

import re
import hashlib
from cryptography.fernet import Fernet
import base64

class DataMasker:
    def __init__(self, secret_key=None):
        if secret_key:
            try:
                self.cipher_suite = Fernet(secret_key)
            except ValueError:
                key_bytes = secret_key.encode()
                if len(key_bytes) < 32:
                    key_bytes = key_bytes + b'\x00' * (32 - len(key_bytes))
                self.cipher_suite = Fernet(base64.urlsafe_b64encode(key_bytes[:32]))
        else:
            self.cipher_suite = None

    def mask_phone(self, phone, mode='star'):
        if not phone:
            return '\\N'
        phone = str(phone).strip()
        
        if mode == 'star':
            if len(phone) == 11:
                return phone[:3] + '****' + phone[-4:]
            elif len(phone) == 8:
                return phone[:2] + '****' + phone[-2:]
            return '***'
        
        elif mode == 'hash':
            return hashlib.md5(phone.encode()).hexdigest()
        
        elif mode == 'encrypt':
            if self.cipher_suite:
                return self.cipher_suite.encrypt(phone.encode()).decode()
            return phone
        
        return phone

    def mask_email(self, email, mode='star'):
        if not email:
            return '\\N'
        email = str(email).strip()
        
        if mode == 'star':
            match = re.match(r'^(.{2})(.*)(@.*)$', email)
            if match:
                return match.group(1) + '****' + match.group(3)
            return '***@***.com'
        
        elif mode == 'hash':
            return hashlib.md5(email.encode()).hexdigest()
        
        elif mode == 'encrypt':
            if self.cipher_suite:
                return self.cipher_suite.encrypt(email.encode()).decode()
            return email
        
        return email

    def mask_id_card(self, id_card, mode='star'):
        if not id_card:
            return '\\N'
        id_card = str(id_card).strip()
        
        if mode == 'star':
            if len(id_card) == 18:
                return id_card[:4] + '**********' + id_card[-4:]
            elif len(id_card) == 15:
                return id_card[:3] + '********' + id_card[-3:]
            return '******************'
        
        elif mode == 'hash':
            return hashlib.md5(id_card.encode()).hexdigest()
        
        elif mode == 'encrypt':
            if self.cipher_suite:
                return self.cipher_suite.encrypt(id_card.encode()).decode()
            return id_card
        
        return id_card

    def mask_name(self, name, mode='star'):
        if not name:
            return '\\N'
        name = str(name).strip()
        
        if mode == 'star':
            if len(name) == 1:
                return '*'
            elif len(name) == 2:
                return name[0] + '*'
            elif len(name) >= 3:
                return name[0] + '**'
            return '***'
        
        elif mode == 'hash':
            return hashlib.md5(name.encode()).hexdigest()
        
        return name

    def mask_address(self, address, mode='star'):
        if not address:
            return '\\N'
        address = str(address).strip()
        
        if mode == 'star':
            if len(address) <= 6:
                return address[:3] + '***'
            elif len(address) <= 10:
                return address[:5] + '***'
            else:
                return address[:6] + '***'
        
        elif mode == 'hash':
            return hashlib.md5(address.encode()).hexdigest()
        
        return address

    def mask_bank_card(self, bank_card, mode='star'):
        if not bank_card:
            return '\\N'
        bank_card = str(bank_card).strip().replace(' ', '').replace('-', '')
        
        if mode == 'star':
            if len(bank_card) >= 16:
                return bank_card[:4] + ' ' + '**** ' * 3 + bank_card[-4:]
            return '**** **** **** ****'
        
        elif mode == 'hash':
            return hashlib.md5(bank_card.encode()).hexdigest()
        
        return bank_card

    def mask_ip(self, ip, mode='star'):
        if not ip:
            return '\\N'
        ip = str(ip).strip()
        
        if mode == 'star':
            parts = ip.split('.')
            if len(parts) == 4:
                return f"{parts[0]}.{parts[1]}.**.**"
            return '***.***.***.***'
        
        elif mode == 'hash':
            return hashlib.md5(ip.encode()).hexdigest()
        
        return ip

    def mask_field(self, value, field_type, mode='star'):
        if value is None or value == '' or value == '\\N':
            return '\\N'
        
        field_type = field_type.lower()
        
        if 'phone' in field_type or 'tel' in field_type or 'mobile' in field_type:
            return self.mask_phone(value, mode)
        elif 'email' in field_type:
            return self.mask_email(value, mode)
        elif 'id_card' in field_type or 'idcard' in field_type or 'idcardno' in field_type:
            return self.mask_id_card(value, mode)
        elif 'name' in field_type:
            return self.mask_name(value, mode)
        elif 'address' in field_type:
            return self.mask_address(value, mode)
        elif 'bank' in field_type or 'card' in field_type:
            return self.mask_bank_card(value, mode)
        elif 'ip' in field_type:
            return self.mask_ip(value, mode)
        elif 'password' in field_type or 'passwd' in field_type or 'pwd' in field_type:
            return '******'
        else:
            return value

    def mask_row(self, row, field_mask_map):
        masked_row = []
        for idx, value in enumerate(row):
            field_name = field_mask_map.get(idx, '')
            mode = field_mask_map.get(f"{idx}_mode", 'star')
            masked_row.append(self.mask_field(value, field_name, mode))
        return masked_row

    def decrypt_field(self, encrypted_value):
        if self.cipher_suite and encrypted_value:
            try:
                return self.cipher_suite.decrypt(encrypted_value.encode()).decode()
            except:
                return encrypted_value
        return encrypted_value

if __name__ == '__main__':
    masker = DataMasker(secret_key="my_secret_key_1234567890123456")
    
    test_data = [
        ('phone', '13812345678'),
        ('email', 'user@example.com'),
        ('id_card', '110101199001011234'),
        ('name', '张三'),
        ('address', '北京市朝阳区建国路88号SOHO现代城A座1801室'),
        ('bank_card', '6222021234567890123'),
        ('ip', '192.168.1.100'),
        ('password', 'password123')
    ]
    
    print("=== Data Masking Test ===")
    for field_type, value in test_data:
        print(f"\n{field_type}:")
        print(f"  Original: {value}")
        print(f"  Star: {masker.mask_field(value, field_type, 'star')}")
        print(f"  Hash: {masker.mask_field(value, field_type, 'hash')}")
        if field_type not in ['password']:
            encrypted = masker.mask_field(value, field_type, 'encrypt')
            print(f"  Encrypt: {encrypted}")
            print(f"  Decrypt: {masker.decrypt_field(encrypted)}")