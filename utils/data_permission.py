#!/usr/bin/env python3

import json
import os

class DataPermissionManager:
    def __init__(self, config_path='data_permission_config.json'):
        self.config_path = config_path
        self.permission_config = self._load_config()

    def _load_config(self):
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return self._get_default_config()

    def _get_default_config(self):
        return {
            "roles": {
                "admin": {
                    "description": "管理员",
                    "permissions": ["ods", "dim", "dwd", "dws", "ads"]
                },
                "developer": {
                    "description": "开发人员",
                    "permissions": ["ods", "dim", "dwd"]
                },
                "analyst": {
                    "description": "分析师",
                    "permissions": ["dim", "dws", "ads"]
                },
                "business": {
                    "description": "业务人员",
                    "permissions": ["ads"]
                },
                "guest": {
                    "description": "访客",
                    "permissions": []
                }
            },
            "users": {},
            "data_levels": {
                "ods": {
                    "name": "原始数据层",
                    "description": "直接同步业务库数据，包含敏感信息",
                    "sensitive": True,
                    "retention_days": 90
                },
                "dim": {
                    "name": "维度数据层",
                    "description": "维度表，已脱敏处理",
                    "sensitive": False,
                    "retention_days": -1
                },
                "dwd": {
                    "name": "明细数据层",
                    "description": "清洗后的明细数据，部分敏感字段已脱敏",
                    "sensitive": True,
                    "retention_days": 30
                },
                "dws": {
                    "name": "汇总数据层",
                    "description": "按主题轻度聚合，不包含敏感信息",
                    "sensitive": False,
                    "retention_days": -1
                },
                "ads": {
                    "name": "应用数据层",
                    "description": "指标报表数据，面向业务",
                    "sensitive": False,
                    "retention_days": -1
                }
            },
            "sensitive_fields": {
                "phone_num": {"mask_type": "phone", "description": "手机号"},
                "email": {"mask_type": "email", "description": "邮箱"},
                "id_card": {"mask_type": "id_card", "description": "身份证号"},
                "name": {"mask_type": "name", "description": "姓名"},
                "address": {"mask_type": "address", "description": "地址"},
                "bank_card": {"mask_type": "bank_card", "description": "银行卡号"},
                "password": {"mask_type": "password", "description": "密码"},
                "ip": {"mask_type": "ip", "description": "IP地址"}
            }
        }

    def save_config(self):
        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(self.permission_config, f, indent=4, ensure_ascii=False)

    def add_role(self, role_name, description, permissions):
        if role_name not in self.permission_config['roles']:
            self.permission_config['roles'][role_name] = {
                "description": description,
                "permissions": permissions
            }
            self.save_config()
            return True
        return False

    def add_user(self, username, role):
        if username not in self.permission_config['users']:
            if role in self.permission_config['roles']:
                self.permission_config['users'][username] = role
                self.save_config()
                return True
        return False

    def get_user_role(self, username):
        return self.permission_config['users'].get(username, 'guest')

    def get_role_permissions(self, role):
        return self.permission_config['roles'].get(role, {}).get('permissions', [])

    def check_permission(self, username, data_level):
        role = self.get_user_role(username)
        permissions = self.get_role_permissions(role)
        return data_level in permissions

    def can_access_layer(self, username, layer):
        return self.check_permission(username, layer)

    def can_access_table(self, username, table_name):
        if table_name.startswith('ods_'):
            return self.check_permission(username, 'ods')
        elif table_name.startswith('dim_'):
            return self.check_permission(username, 'dim')
        elif table_name.startswith('dwd_'):
            return self.check_permission(username, 'dwd')
        elif table_name.startswith('dws_'):
            return self.check_permission(username, 'dws')
        elif table_name.startswith('ads_'):
            return self.check_permission(username, 'ads')
        return False

    def get_user_accessible_layers(self, username):
        role = self.get_user_role(username)
        permissions = self.get_role_permissions(role)
        return permissions

    def get_layer_info(self, layer):
        return self.permission_config['data_levels'].get(layer, {})

    def is_layer_sensitive(self, layer):
        return self.get_layer_info(layer).get('sensitive', False)

    def get_sensitive_fields(self):
        return self.permission_config['sensitive_fields']

    def add_sensitive_field(self, field_name, mask_type, description):
        if field_name not in self.permission_config['sensitive_fields']:
            self.permission_config['sensitive_fields'][field_name] = {
                "mask_type": mask_type,
                "description": description
            }
            self.save_config()
            return True
        return False

    def generate_hive_grant_sql(self, username, table_name):
        if not self.can_access_table(username, table_name):
            return None
        
        role = self.get_user_role(username)
        permissions = self.get_role_permissions(role)
        
        layer = table_name.split('_')[0]
        database = f"gmall_{layer}"
        
        if layer in permissions:
            return f"GRANT SELECT ON TABLE {database}.{table_name} TO USER '{username}';"
        return None

    def generate_role_based_grants(self):
        grants = []
        for role_name, role_info in self.permission_config['roles'].items():
            for layer in role_info['permissions']:
                database = f"gmall_{layer}"
                grants.append(f"GRANT SELECT ON DATABASE {database} TO ROLE {role_name};")
        return grants

    def audit_user_access(self, username, table_name, action='SELECT'):
        return {
            "username": username,
            "table_name": table_name,
            "action": action,
            "allowed": self.can_access_table(username, table_name),
            "role": self.get_user_role(username),
            "timestamp": "2024-01-01 00:00:00"
        }

if __name__ == '__main__':
    permission_manager = DataPermissionManager()
    
    print("=== Data Permission Manager Test ===")
    
    print("\n1. 角色权限配置:")
    for role, info in permission_manager.permission_config['roles'].items():
        print(f"  {role}: {info['description']} - 权限: {info['permissions']}")
    
    print("\n2. 数据分层配置:")
    for layer, info in permission_manager.permission_config['data_levels'].items():
        print(f"  {layer}: {info['name']} - 敏感: {info['sensitive']}")
    
    print("\n3. 用户权限检查:")
    test_users = ['admin_user', 'analyst_user', 'business_user']
    
    for user in test_users:
        permission_manager.add_user(user, 'admin' if user == 'admin_user' else ('analyst' if user == 'analyst_user' else 'business'))
        
        print(f"\n  用户: {user}")
        print(f"    角色: {permission_manager.get_user_role(user)}")
        print(f"    可访问层: {permission_manager.get_user_accessible_layers(user)}")
        print(f"    可访问 ods_user_info: {permission_manager.can_access_table(user, 'ods_user_info')}")
        print(f"    可访问 ads_gmv_day: {permission_manager.can_access_table(user, 'ads_gmv_day')}")
    
    print("\n4. 生成授权SQL:")
    sql = permission_manager.generate_hive_grant_sql('admin_user', 'ods_user_info')
    print(f"   admin_user -> ods_user_info: {sql}")
    
    print("\n5. 审计日志:")
    audit = permission_manager.audit_user_access('analyst_user', 'dwd_order_detail')
    print(f"   {audit}")
    
    permission_manager.save_config()
    print("\n配置已保存!")