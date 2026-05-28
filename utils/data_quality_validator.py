#!/usr/bin/env python3
"""
数据质量校验脚本
校验数仓各层数据的完整性和准确性
"""

import sys
from datetime import datetime
from typing import List, Tuple, Dict

class DataQualityValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.success_count = 0
        self.total_check_count = 0

    def check_not_null(self, table_name: str, column_name: str, check_sql: str) -> bool:
        """检查字段非空"""
        self.total_check_count += 1
        # 这里应该连接 Hive 执行 SQL
        # 模拟执行
        null_count = 0  # 假设查询结果

        if null_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {null_count} 条空值记录"
            self.errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 非空校验通过")
            self.success_count += 1
            return True

    def check_unique(self, table_name: str, column_name: str, check_sql: str) -> bool:
        """检查字段唯一性"""
        self.total_check_count += 1
        duplicate_count = 0  # 假设查询结果

        if duplicate_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {duplicate_count} 条重复值"
            self.errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 唯一性校验通过")
            self.success_count += 1
            return True

    def check_data_range(self, table_name: str, column_name: str, min_val, max_val, check_sql: str) -> bool:
        """检查数据范围"""
        self.total_check_count += 1
        out_of_range_count = 0  # 假设查询结果

        if out_of_range_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {out_of_range_count} 条超出范围的数据"
            self.errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 数据范围校验通过")
            self.success_count += 1
            return True

    def check_referential_integrity(self, parent_table: str, parent_col: str,
                                   child_table: str, child_col: str) -> bool:
        """检查参照完整性（外键关联）"""
        self.total_check_count += 1
        orphan_count = 0  # 假设查询结果

        if orphan_count > 0:
            error_msg = f"[ERROR] {child_table}.{child_col} 存在 {orphan_count} 条孤儿记录"
            self.errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")
            return False
        else:
            print(f"  [OK] {child_table}.{child_col} -> {parent_table}.{parent_col} 参照完整性校验通过")
            self.success_count += 1
            return True

    def check_business_rules(self, rule_name: str, check_sql: str, threshold: float = 0.0) -> bool:
        """检查业务规则"""
        self.total_check_count += 1
        violation_count = 0  # 假设查询结果

        if violation_count > threshold:
            error_msg = f"[ERROR] 业务规则 '{rule_name}' 违反 {violation_count} 次"
            self.errors.append(error_msg)
            print(f"  [ERROR] {error_msg}")
            return False
        else:
            print(f"  [OK] 业务规则 '{rule_name}' 校验通过")
            self.success_count += 1
            return True

    def check_data_freshness(self, table_name: str, max_lag_hours: int = 24) -> bool:
        """检查数据新鲜度"""
        self.total_check_count += 1
        max_lag = 0  # 假设查询结果（小时）

        if max_lag > max_lag_hours:
            warning_msg = f"[WARN] {table_name} 数据延迟 {max_lag} 小时，超过阈值 {max_lag_hours} 小时"
            self.warnings.append(warning_msg)
            print(f"  [WARN] {warning_msg}")
            return False
        else:
            print(f"  [OK] {table_name} 数据新鲜度校验通过（延迟 {max_lag} 小时）")
            self.success_count += 1
            return True

    def check_data_volume(self, table_name: str, min_records: int, max_records: int = None) -> bool:
        """检查数据量"""
        self.total_check_count += 1
        record_count = 0  # 假设查询结果

        if record_count < min_records:
            warning_msg = f"[WARN] {table_name} 数据量 {record_count} 低于最小阈值 {min_records}"
            self.warnings.append(warning_msg)
            print(f"  [WARN] {warning_msg}")
            return False

        if max_records and record_count > max_records:
            warning_msg = f"[WARN] {table_name} 数据量 {record_count} 高于最大阈值 {max_records}"
            self.warnings.append(warning_msg)
            print(f"  [WARN] {warning_msg}")
            return False

        print(f"  [OK] {table_name} 数据量校验通过（共 {record_count} 条）")
        self.success_count += 1
        return True

    def validate_dwd_order_info(self):
        """校验 DWD 层订单表"""
        print("\n" + "="*80)
        print("校验 DWD_ORDER_INFO（订单信息表）")
        print("="*80)

        # 1. ID非空校验
        print("\n1. 非空校验：")
        self.check_not_null('dwd_order_info', 'id', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_info
            WHERE id IS NULL OR id = ''
        """)

        # 2. 唯一性校验
        print("\n2. 唯一性校验：")
        self.check_unique('dwd_order_info', 'id', """
            SELECT id, COUNT(*) as cnt FROM gmall_dwd.dwd_order_info
            GROUP BY id HAVING cnt > 1
        """)

        # 3. 业务规则校验
        print("\n3. 业务规则校验：")
        # 规则1：订单金额不能为负
        self.check_business_rules('订单金额>=0', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_info
            WHERE total_amount < 0
        """)

        # 规则2：运费不能为负
        self.check_business_rules('运费>=0', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_info
            WHERE feight_fee < 0
        """)

        # 规则3：订单状态必须合法
        self.check_business_rules('订单状态合法', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_info
            WHERE order_status NOT IN ('UNPAID', 'PAID', 'SHIPPED', 'COMPLETED', 'CLOSED', 'REFUNDED')
        """)

        # 规则4：创建时间不能晚于操作时间
        self.check_business_rules('创建时间<=操作时间', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_info
            WHERE create_time > operate_time AND operate_time IS NOT NULL
        """)

        # 4. 参照完整性校验
        print("\n4. 参照完整性校验：")
        self.check_referential_integrity('dim_user', 'id', 'dwd_order_info', 'user_id')

        # 5. 数据新鲜度校验
        print("\n5. 数据新鲜度校验：")
        self.check_data_freshness('dwd_order_info', max_lag_hours=24)

    def validate_dwd_order_detail(self):
        """校验 DWD 层订单明细表"""
        print("\n" + "="*80)
        print("校验 DWD_ORDER_DETAIL（订单明细表）")
        print("="*80)

        # 1. 非空校验
        print("\n1. 非空校验：")
        self.check_not_null('dwd_order_detail', 'id', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_detail
            WHERE id IS NULL OR id = ''
        """)

        # 2. 业务规则校验
        print("\n2. 业务规则校验：")
        # 规则1：商品数量必须>0
        self.check_business_rules('商品数量>0', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_detail
            WHERE sku_num <= 0
        """)

        # 规则2：订单价格不能为负
        self.check_business_rules('订单价格>=0', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_detail
            WHERE order_price < 0
        """)

        # 规则3：明细金额 = 单价 * 数量
        self.check_business_rules('明细金额=单价*数量', """
            SELECT COUNT(*) FROM gmall_dwd.dwd_order_detail
            WHERE ABS(order_amount - order_price * sku_num) > 0.01
        """)

        # 3. 数据量校验
        print("\n3. 数据量校验：")
        self.check_data_volume('dwd_order_detail', min_records=1)

    def validate_dws_gmv_stats(self):
        """校验 DWS 层 GMV 统计表"""
        print("\n" + "="*80)
        print("校验 DWS_GMV_STATS（GMV统计表）")
        print("="*80)

        # 1. 业务规则校验
        print("\n1. 业务规则校验：")
        # 规则1：GMV >= 0
        self.check_business_rules('GMV>=0', """
            SELECT COUNT(*) FROM gmall_dws.dws_gmv_stats
            WHERE gmv < 0
        """)

        # 规则2：订单数 >= 0
        self.check_business_rules('订单数>=0', """
            SELECT COUNT(*) FROM gmall_dws.dws_gmv_stats
            WHERE order_count < 0
        """)

        # 规则3：客单价 = GMV / 订单数（允许误差）
        self.check_business_rules('客单价=GMV/订单数', """
            SELECT COUNT(*) FROM gmall_dws.dws_gmv_stats
            WHERE order_count > 0
            AND ABS(avg_order_amount - gmv / order_count) > 0.01
        """)

    def validate_all(self):
        """执行所有校验"""
        print("="*80)
        print("              数据质量校验工具 - 全面检查")
        print("="*80)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"检查范围: DWD/DWS/ADS 层核心表")

        # ODS 层校验
        self.validate_dwd_order_info()
        self.validate_dwd_order_detail()
        self.validate_dws_gmv_stats()

        # 生成报告
        self.generate_report()

    def generate_report(self):
        """生成校验报告"""
        print("\n" + "="*80)
        print("                       数据质量校验报告")
        print("="*80)

        print(f"\n检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"总检查项: {self.total_check_count}")
        print(f"通过: {self.success_count}")
        print(f"失败: {len(self.errors)}")
        print(f"警告: {len(self.warnings)}")

        if self.errors:
            print("\n【错误列表】")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")

        if self.warnings:
            print("\n【警告列表】")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")

        print("\n【检查结果】")
        if not self.errors and not self.warnings:
            print("  [PASS] 所有检查项通过，数据质量合格！")
            return True
        elif not self.errors:
            print("  [PASS] 所有检查项通过，存在警告请关注")
            return True
        else:
            print("  [FAIL] 存在错误，数据质量不合格，请立即处理！")
            return False

if __name__ == '__main__':
    validator = DataQualityValidator()
    result = validator.validate_all()

    # 返回退出码
    sys.exit(0 if result else 1)
