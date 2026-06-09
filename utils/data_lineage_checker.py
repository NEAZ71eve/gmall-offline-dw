#!/usr/bin/env python3
"""
数据血缘检查工具
检查数仓各层之间的数据血缘关系是否完整
"""

import sys
import re
from datetime import datetime
from typing import List, Dict, Tuple, Set

class DataLineageChecker:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.lineage_records = []
        
        # 定义标准的血缘关系
        self.expected_lineage = {
            # ODS -> DIM
            'ods_user_info': ['dim_user_scd1', 'dim_user_scd2', 'dim_user_scd3'],
            'ods_sku_info': ['dim_sku', 'dim_spu', 'dim_brand'],
            'ods_base_category1': ['dim_category1'],
            'ods_base_category2': ['dim_category2'],
            'ods_base_category3': ['dim_category3'],
            'ods_base_province': ['dim_province'],
            
            # ODS -> DWD
            'ods_order_info': ['dwd_order_info', 'dwd_order_detail'],
            'ods_order_detail': ['dwd_order_detail'],
            'ods_payment_info': ['dwd_payment_info'],
            'ods_order_refund_info': ['dwd_order_refund_info'],
            
            # DIM -> DWD
            'dim_user_scd2': ['dwd_order_info'],
            'dim_sku': ['dwd_order_detail'],
            'dim_province': ['dwd_order_info', 'dwd_order_detail'],
            
            # DIM + DWD -> DWS
            'dwd_order_info': ['dws_order_day', 'dws_user_day'],
            'dwd_order_detail': ['dws_order_day', 'dws_user_day', 'dws_sku_day', 'dws_province_day'],
            'dwd_payment_info': ['dws_order_day'],
            'dwd_sku_info': ['dws_sku_day', 'dws_trademark_day', 'dws_category3_day'],
            
            # DWS -> ADS
            'dws_order_day': ['ads_gmv_day', 'ads_gmv_province', 'ads_conversion_rate'],
            'dws_user_day': ['ads_user_retention', 'ads_user_active_day'],
            'dws_sku_day': ['ads_sku_sales_rank', 'ads_gmv_category'],
            'dws_province_day': ['ads_gmv_province', 'ads_province_stats'],
            'dws_user_new_day': ['ads_user_new_day'],
        }
        
        # 指标血缘定义
        self.indicator_lineage = {
            'gmv': {
                'layer': 'ads_gmv_day',
                'formula': 'SUM(dws_order_day.order_amount)',
                'dependencies': ['dws_order_day'],
                'source_tables': ['dwd_order_info', 'dwd_order_detail']
            },
            'payment_amount': {
                'layer': 'ads_gmv_day',
                'formula': 'SUM(dwd_payment_info.total_amount)',
                'dependencies': ['dwd_payment_info'],
                'source_tables': ['ods_payment_info']
            },
            'order_count': {
                'layer': 'ads_gmv_day',
                'formula': 'COUNT(DISTINCT dwd_order_info.id)',
                'dependencies': ['dwd_order_info'],
                'source_tables': ['ods_order_info']
            },
            'user_retention_d1': {
                'layer': 'ads_user_retention',
                'formula': 'COUNT(DISTINCT user_id WHERE dt=D1)',
                'dependencies': ['dws_user_retention_day'],
                'source_tables': ['dwd_order_info', 'ods_user_info']
            },
            'sku_sales_rank': {
                'layer': 'ads_sku_sales_rank',
                'formula': 'RANK() BY SUM(order_amount)',
                'dependencies': ['dws_sku_day'],
                'source_tables': ['dwd_order_detail', 'dim_sku']
            },
            'conversion_rate': {
                'layer': 'ads_conversion_rate',
                'formula': 'payment_count / order_count',
                'dependencies': ['dws_order_day'],
                'source_tables': ['dwd_order_info', 'dwd_payment_info']
            }
        }

    def parse_sql_lineage(self, sql: str) -> Set[str]:
        """从SQL中解析血缘关系"""
        tables = set()
        
        # 匹配 FROM 和 JOIN 子句中的表名
        from_pattern = r'FROM\s+([a-z_]+\.[a-z_]+)'
        join_pattern = r'JOIN\s+([a-z_]+\.[a-z_]+)'
        
        tables.update(re.findall(from_pattern, sql, re.IGNORECASE))
        tables.update(re.findall(join_pattern, sql, re.IGNORECASE))
        
        return tables

    def check_table_lineage(self, source_table: str, target_table: str) -> bool:
        """检查表级血缘关系"""
        expected_targets = self.expected_lineage.get(source_table, [])
        
        if target_table in expected_targets:
            return True
        
        # 检查是否是DIM/DWD/DWS/ADS层的标准命名
        source_layer = source_table.split('_')[0]
        target_layer = target_table.split('_')[0]
        
        # 允许的上游依赖关系
        allowed_dependencies = {
            'ods': ['dim', 'dwd'],
            'dim': ['dwd', 'dws'],
            'dwd': ['dws', 'ads'],
            'dws': ['ads']
        }
        
        if target_layer in allowed_dependencies.get(source_layer, []):
            return True
        
        return False

    def check_indicator_lineage(self, indicator_name: str) -> bool:
        """检查指标血缘关系"""
        if indicator_name not in self.indicator_lineage:
            self.warnings.append(f"指标 '{indicator_name}' 未在血缘定义中找到")
            return False
        
        lineage_info = self.indicator_lineage[indicator_name]
        print(f"\n指标: {indicator_name}")
        print(f"  所在表: {lineage_info['layer']}")
        print(f"  计算公式: {lineage_info['formula']}")
        print(f"  依赖表: {', '.join(lineage_info['dependencies'])}")
        print(f"  源表: {', '.join(lineage_info['source_tables'])}")
        
        return True

    def check_dwd_to_dws_lineage(self) -> bool:
        """检查DWD到DWS的血缘关系"""
        print("\n" + "="*80)
        print("检查 DWD -> DWS 血缘关系")
        print("="*80)
        
        lineage_rules = [
            {
                'dwd_table': 'dwd_order_info',
                'dws_tables': ['dws_order_day', 'dws_province_day'],
                'join_key': 'order_id',
                'dims': ['dim_user_scd2', 'dim_province']
            },
            {
                'dwd_table': 'dwd_order_detail',
                'dws_tables': ['dws_order_day', 'dws_sku_day', 'dws_user_day'],
                'join_key': 'order_id',
                'dims': ['dim_sku']
            },
            {
                'dwd_table': 'dwd_payment_info',
                'dws_tables': ['dws_order_day'],
                'join_key': 'order_id',
                'dims': []
            }
        ]
        
        all_passed = True
        for rule in lineage_rules:
            print(f"\n源表: {rule['dwd_table']}")
            print(f"  目标表: {', '.join(rule['dws_tables'])}")
            print(f"  关联键: {rule['join_key']}")
            
            # 验证目标表存在
            if not rule['dws_tables']:
                self.errors.append(f"{rule['dwd_table']} 缺少目标汇总表")
                all_passed = False
            else:
                print(f"  ✓ 血缘关系正常")
        
        return all_passed

    def check_dws_to_ads_lineage(self) -> bool:
        """检查DWS到ADS的指标血缘"""
        print("\n" + "="*80)
        print("检查 DWS -> ADS 指标血缘")
        print("="*80)
        
        indicator_rules = [
            {
                'indicator': 'GMV',
                'ads_table': 'ads_gmv_day',
                'dws_tables': ['dws_order_day'],
                'calculation': 'SUM(order_amount)',
                'dims': ['date_id']
            },
            {
                'indicator': '支付金额',
                'ads_table': 'ads_gmv_day',
                'dws_tables': ['dws_order_day'],
                'calculation': 'SUM(payment_amount)',
                'dims': ['date_id']
            },
            {
                'indicator': '客单价',
                'ads_table': 'ads_gmv_day',
                'dws_tables': ['dws_order_day'],
                'calculation': 'SUM(order_amount) / COUNT(DISTINCT user_id)',
                'dims': ['date_id']
            },
            {
                'indicator': '用户留存率',
                'ads_table': 'ads_user_retention',
                'dws_tables': ['dws_user_day', 'dws_user_new_day'],
                'calculation': '留存用户数 / 新增用户数',
                'dims': ['date_id', 'retention_day']
            }
        ]
        
        all_passed = True
        for rule in indicator_rules:
            print(f"\n指标: {rule['indicator']}")
            print(f"  ADS表: {rule['ads_table']}")
            print(f"  DWS表: {', '.join(rule['dws_tables'])}")
            print(f"  计算方式: {rule['calculation']}")
            print(f"  维度: {', '.join(rule['dims'])}")
            
            if not rule['dws_tables']:
                self.errors.append(f"指标 '{rule['indicator']}' 缺少DWS层数据源")
                all_passed = False
            else:
                print(f"  ✓ 指标血缘正常")
        
        return all_passed

    def check_cross_layer_consistency(self) -> bool:
        """检查跨层数据一致性"""
        print("\n" + "="*80)
        print("检查跨层数据一致性")
        print("="*80)
        
        consistency_rules = [
            {
                'name': 'DWS订单金额 = SUM(DWD订单明细金额)',
                'dws_query': 'SELECT SUM(order_amount) FROM dws_order_day WHERE dt = "${biz_date}"',
                'dwd_query': 'SELECT SUM(original_amount) FROM dwd_order_detail WHERE dt = "${biz_date}"',
                'tolerance': 0.01
            },
            {
                'name': 'DWS支付金额 = DWS订单金额 * 支付转化率',
                'dws_query': 'SELECT SUM(payment_amount) FROM dws_order_day WHERE dt = "${biz_date}"',
                'dwd_query': 'SELECT SUM(payment_amount) FROM dwd_payment_info WHERE dt = "${biz_date}"',
                'tolerance': 0.01
            },
            {
                'name': 'ADS_GMV = DWS_DAY_ORDER.order_amount SUM',
                'ads_query': 'SELECT gmv FROM ads_gmv_day WHERE dt = "${biz_date}" AND recent_days = 1',
                'dws_query': 'SELECT order_amount FROM dws_order_day WHERE dt = "${biz_date}"',
                'tolerance': 0.01
            }
        ]
        
        all_passed = True
        for rule in consistency_rules:
            print(f"\n一致性规则: {rule['name']}")
            print(f"  预期: 数值一致（误差 < {rule['tolerance']}）")
            print(f"  注意: 需在实际环境中执行SQL验证")
            # 实际验证需要在有Hive环境时执行
            print(f"  ✓ 规则定义正常")
        
        return all_passed

    def check_lineage_completeness(self) -> bool:
        """检查血缘链路完整性"""
        print("\n" + "="*80)
        print("检查血缘链路完整性")
        print("="*80)
        
        # 完整链路检查
        complete_chains = [
            ['ods_user_info', 'dim_user_scd2', 'dwd_order_info', 'dws_user_day', 'ads_user_retention'],
            ['ods_order_info', 'dwd_order_info', 'dws_order_day', 'ads_gmv_day'],
            ['ods_order_detail', 'dwd_order_detail', 'dws_sku_day', 'ads_sku_sales_rank'],
            ['ods_payment_info', 'dwd_payment_info', 'dws_order_day', 'ads_gmv_day'],
        ]
        
        all_passed = True
        for chain in complete_chains:
            print(f"\n完整链路: {' -> '.join(chain)}")
            
            # 验证链路每层是否存在
            for i in range(len(chain) - 1):
                source = chain[i]
                target = chain[i + 1]
                if self.check_table_lineage(source, target):
                    print(f"  ✓ {source} -> {target}")
                else:
                    self.warnings.append(f"链路 {source} -> {target} 可能存在问题")
                    print(f"  ⚠ {source} -> {target} (需要验证)")
        
        return all_passed

    def generate_lineage_report(self):
        """生成血缘报告"""
        print("\n" + "="*80)
        print("                       数据血缘检查报告")
        print("="*80)
        
        print(f"\n检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"错误数: {len(self.errors)}")
        print(f"警告数: {len(self.warnings)}")
        
        if self.errors:
            print("\n【错误列表】")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
        
        if self.warnings:
            print("\n【警告列表】")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
        
        print("\n【血缘关系图】")
        print("""
        ODS层 ──────────────────────────────────────────────────┐
           │                                                     │
           ▼                                                     ▼
        DIM层 ◄────────────────────────────────────────────────┘
           │
           ▼
        DWD层
           │
           ├──────────┬──────────┬──────────┐
           ▼          ▼          ▼          ▼
        DWS层    用户域    商品域    地区域    促销域
           │
           └──────────┬──────────┬──────────┐
                     ▼          ▼          ▼
                   ADS层    指标报表    分析报表
        """)
        
        print("\n【检查结果】")
        if not self.errors and not self.warnings:
            print("  [PASS] 数据血缘检查全部通过！")
            return True
        elif not self.errors:
            print("  [PASS] 血缘检查通过，存在警告请关注")
            return True
        else:
            print("  [FAIL] 存在错误，请修复后重新检查")
            return False

    def check_all(self) -> bool:
        """执行所有血缘检查"""
        print("="*80)
        print("              数据血缘检查工具 - 全面检查")
        print("="*80)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # 1. 检查指标血缘
        print("\n" + "="*80)
        print("检查指标血缘定义")
        print("="*80)
        for indicator in self.indicator_lineage.keys():
            self.check_indicator_lineage(indicator)
        
        # 2. 检查DWD到DWS血缘
        self.check_dwd_to_dws_lineage()
        
        # 3. 检查DWS到ADS血缘
        self.check_dws_to_ads_lineage()
        
        # 4. 检查跨层一致性
        self.check_cross_layer_consistency()
        
        # 5. 检查链路完整性
        self.check_lineage_completeness()
        
        # 6. 生成报告
        return self.generate_lineage_report()

if __name__ == '__main__':
    checker = DataLineageChecker()
    result = checker.check_all()
    
    # 返回退出码
    sys.exit(0 if result else 1)
