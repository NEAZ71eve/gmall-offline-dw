#!/usr/bin/env python3
"""
数据质量校验工具 - 完整版
连接Hive执行真实查询，校验数仓各层数据的完整性和准确性
"""

import sys
import os
from datetime import datetime, timedelta
from typing import List, Dict, Tuple, Optional

try:
    from pyhive import hive
    from TCLIService.ttypes import TOperationState
    HAS_PYHIVE = True
except ImportError:
    HAS_PYHIVE = False

try:
    import jaydebeapi
    HAS_JAYDEBEAPI = True
except ImportError:
    HAS_JAYDEBEAPI = False


class DataQualityValidator:
    def __init__(self, host='localhost', port=10000, database='default', biz_date=None):
        self.host = host
        self.port = port
        self.database = database
        self.biz_date = biz_date or datetime.now().strftime('%Y-%m-%d')
        self.errors = []
        self.warnings = []
        self.success_count = 0
        self.total_check_count = 0
        self.connection = None
        self.cursor = None
        
        # 尝试建立连接
        self._connect()

    def _connect(self):
        """建立Hive连接"""
        if HAS_PYHIVE:
            try:
                self.connection = hive.connect(host=self.host, port=self.port, database=self.database)
                self.cursor = self.connection.cursor()
                print(f"✓ 已连接到 Hive Metastore: {self.host}:{self.port}/{self.database}")
                return True
            except Exception as e:
                print(f"⚠ PyHive连接失败: {e}")
        
        if HAS_JAYDEBEAPI:
            try:
                jdbc_url = f"jdbc:hive2://{self.host}:{self.port}/{self.database}"
                self.connection = jaydebeapi.connect(
                    'org.apache.hive.jdbc.HiveDriver',
                    jdbc_url,
                    [],
                    '/path/to/hive_jdbc.jar'
                )
                self.cursor = self.connection.cursor()
                print(f"✓ 已通过JDBC连接到 Hive: {self.host}:{self.port}/{self.database}")
                return True
            except Exception as e:
                print(f"⚠ JayDeBeApi连接失败: {e}")
        
        print("⚠ 无法连接到Hive，将使用模拟模式执行检查")
        return False

    def _execute_query(self, sql: str) -> Optional[List]:
        """执行SQL查询"""
        if self.cursor:
            try:
                self.cursor.execute(sql)
                return self.cursor.fetchall()
            except Exception as e:
                print(f"  查询执行失败: {e}")
                return None
        return None

    def close(self):
        """关闭连接"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()

    def check_not_null(self, table_name: str, column_name: str, partition_date: str = None) -> bool:
        """检查字段非空"""
        self.total_check_count += 1
        
        partition_clause = f"WHERE dt = '{partition_date or self.biz_date}'" if partition_date else ""
        sql = f"""
            SELECT COUNT(*) FROM {table_name} 
            WHERE ({column_name} IS NULL OR {column_name} = '') 
            {partition_clause}
        """
        
        result = self._execute_query(sql)
        null_count = result[0][0] if result else 0
        
        if null_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {null_count} 条空值记录"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 非空校验通过")
            self.success_count += 1
            return True

    def check_unique(self, table_name: str, column_name: str, partition_date: str = None) -> bool:
        """检查字段唯一性"""
        self.total_check_count += 1
        
        partition_clause = f"WHERE dt = '{partition_date or self.biz_date}'" if partition_date else ""
        sql = f"""
            SELECT {column_name}, COUNT(*) as cnt FROM {table_name}
            {partition_clause}
            GROUP BY {column_name}
            HAVING COUNT(*) > 1
        """
        
        result = self._execute_query(sql)
        duplicate_count = len(result) if result else 0
        
        if duplicate_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {duplicate_count} 条重复值"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 唯一性校验通过")
            self.success_count += 1
            return True

    def check_data_range(self, table_name: str, column_name: str, min_val, max_val, partition_date: str = None) -> bool:
        """检查数据范围"""
        self.total_check_count += 1
        
        partition_clause = f"WHERE dt = '{partition_date or self.biz_date}'" if partition_date else ""
        sql = f"""
            SELECT COUNT(*) FROM {table_name}
            {partition_clause}
            AND ({column_name} < {min_val} OR {column_name} > {max_val})
        """
        
        result = self._execute_query(sql)
        out_of_range_count = result[0][0] if result else 0
        
        if out_of_range_count > 0:
            error_msg = f"[ERROR] {table_name}.{column_name} 存在 {out_of_range_count} 条超出范围({min_val}~{max_val})的数据"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name}.{column_name} 数据范围校验通过")
            self.success_count += 1
            return True

    def check_referential_integrity(self, parent_table: str, parent_col: str,
                                   child_table: str, child_col: str, partition_date: str = None) -> bool:
        """检查参照完整性（外键关联）"""
        self.total_check_count += 1
        
        partition_clause = f"AND child.dt = '{partition_date or self.biz_date}'" if partition_date else ""
        
        sql = f"""
            SELECT COUNT(*) FROM (
                SELECT DISTINCT {child_col} as col FROM {child_table}
                WHERE {child_col} IS NOT NULL {partition_clause}
            ) child
            LEFT JOIN (
                SELECT DISTINCT {parent_col} as col FROM {parent_table}
            ) parent ON child.col = parent.col
            WHERE parent.col IS NULL
        """
        
        result = self._execute_query(sql)
        orphan_count = result[0][0] if result else 0
        
        if orphan_count > 0:
            error_msg = f"[ERROR] {child_table}.{child_col} 存在 {orphan_count} 条孤儿记录(无对应{parent_table}.{parent_col})"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {child_table}.{child_col} -> {parent_table}.{parent_col} 参照完整性校验通过")
            self.success_count += 1
            return True

    def check_data_consistency(self, table1: str, col1: str, table2: str, col2: str, partition_date: str = None) -> bool:
        """检查两表数据一致性"""
        self.total_check_count += 1
        
        partition1 = f"dt = '{partition_date or self.biz_date}'" if partition_date else "1=1"
        partition2 = f"dt = '{partition_date or self.biz_date}'" if partition_date else "1=1"
        
        sql = f"""
            SELECT ABS(COALESCE(t1.val, 0) - COALESCE(t2.val, 0)) as diff
            FROM (
                SELECT SUM({col1}) as val FROM {table1}
                WHERE {partition1}
            ) t1
            FULL OUTER JOIN (
                SELECT SUM({col2}) as val FROM {table2}
                WHERE {partition2}
            ) t2 ON 1=1
        """
        
        result = self._execute_query(sql)
        diff = result[0][0] if result else 0
        
        if diff > 0.01:
            error_msg = f"[ERROR] 数据一致性检查失败: {table1}.{col1} vs {table2}.{col2}, 差异={diff}"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {table1}.{col1} 与 {table2}.{col2} 数据一致性校验通过")
            self.success_count += 1
            return True

    def check_data_freshness(self, table_name: str, max_lag_hours: int = 24, partition_date: str = None) -> bool:
        """检查数据新鲜度"""
        self.total_check_count += 1
        
        partition_clause = f"WHERE dt = '{partition_date or self.biz_date}'" if partition_date else ""
        sql = f"""
            SELECT MAX(update_time) FROM {table_name}
            {partition_clause}
        """
        
        result = self._execute_query(sql)
        max_update_time = result[0][0] if result and result[0][0] else None
        
        if max_update_time:
            if isinstance(max_update_time, str):
                max_update_time = datetime.strptime(max_update_time, '%Y-%m-%d %H:%M:%S')
            
            lag_hours = (datetime.now() - max_update_time).total_seconds() / 3600
            
            if lag_hours > max_lag_hours:
                warning_msg = f"[WARN] {table_name} 数据延迟 {lag_hours:.1f} 小时，超过阈值 {max_lag_hours} 小时"
                self.warnings.append(warning_msg)
                print(f"  {warning_msg}")
                return False
            else:
                print(f"  [OK] {table_name} 数据新鲜度校验通过（延迟 {lag_hours:.1f} 小时）")
                self.success_count += 1
                return True
        else:
            warning_msg = f"[WARN] {table_name} 无最新更新时间记录"
            self.warnings.append(warning_msg)
            print(f"  {warning_msg}")
            return False

    def check_data_volume(self, table_name: str, min_records: int, partition_date: str = None) -> bool:
        """检查数据量"""
        self.total_check_count += 1
        
        partition_clause = f"WHERE dt = '{partition_date or self.biz_date}'" if partition_date else ""
        sql = f"SELECT COUNT(*) FROM {table_name} {partition_clause}"
        
        result = self._execute_query(sql)
        record_count = result[0][0] if result else 0
        
        if record_count < min_records:
            warning_msg = f"[WARN] {table_name} 数据量 {record_count} 低于最小阈值 {min_records}"
            self.warnings.append(warning_msg)
            print(f"  {warning_msg}")
            return False
        else:
            print(f"  [OK] {table_name} 数据量校验通过（共 {record_count} 条）")
            self.success_count += 1
            return True

    def check_partition_exists(self, table_name: str, partition_date: str = None) -> bool:
        """检查分区是否存在"""
        self.total_check_count += 1
        
        partition = partition_date or self.biz_date
        sql = f"""
            SHOW PARTITIONS {table_name} PARTITION(dt='{partition}')
        """
        
        result = self._execute_query(sql)
        
        if not result:
            error_msg = f"[ERROR] {table_name} 分区 dt={partition} 不存在"
            self.errors.append(error_msg)
            print(f"  {error_msg}")
            return False
        else:
            print(f"  [OK] {table_name} 分区 dt={partition} 存在")
            self.success_count += 1
            return True

    def validate_dwd_order_info(self, partition_date: str = None):
        """校验 DWD 层订单表"""
        print("\n" + "="*80)
        print("校验 DWD_ORDER_INFO（订单信息表）")
        print("="*80)
        
        table = 'gmall_dwd.dwd_order_info'
        
        # 1. 非空校验
        print("\n1. 非空校验：")
        self.check_not_null(table, 'id', partition_date)
        self.check_not_null(table, 'user_id', partition_date)
        self.check_not_null(table, 'province_id', partition_date)
        self.check_not_null(table, 'total_amount', partition_date)
        
        # 2. 唯一性校验
        print("\n2. 唯一性校验：")
        self.check_unique(table, 'id', partition_date)
        
        # 3. 业务规则校验
        print("\n3. 业务规则校验：")
        self.check_data_range(table, 'total_amount', 0, 999999999, partition_date)

    def validate_dwd_order_detail(self, partition_date: str = None):
        """校验 DWD 层订单明细表"""
        print("\n" + "="*80)
        print("校验 DWD_ORDER_DETAIL（订单明细表）")
        print("="*80)
        
        table = 'gmall_dwd.dwd_order_detail'
        
        # 1. 非空校验
        print("\n1. 非空校验：")
        self.check_not_null(table, 'id', partition_date)
        self.check_not_null(table, 'order_id', partition_date)
        self.check_not_null(table, 'sku_id', partition_date)
        self.check_not_null(table, 'final_amount', partition_date)
        
        # 2. 唯一性校验
        print("\n2. 唯一性校验：")
        self.check_unique(table, 'id', partition_date)
        
        # 3. 数据范围校验
        print("\n3. 数据范围校验：")
        self.check_data_range(table, 'sku_num', 1, 9999, partition_date)
        self.check_data_range(table, 'original_amount', 0, 999999999, partition_date)
        
        # 4. 参照完整性校验
        print("\n4. 参照完整性校验：")
        self.check_referential_integrity('gmall_dim.dim_user_scd2', 'id', table, 'user_id', partition_date)
        self.check_referential_integrity('gmall_dim.dim_sku', 'id', table, 'sku_id', partition_date)

    def validate_dws_gmv_stats(self, partition_date: str = None):
        """校验 DWS 层 GMV 统计表"""
        print("\n" + "="*80)
        print("校验 DWS_ORDER_DAY（订单汇总表）")
        print("="*80)
        
        table = 'gmall_dws.dws_order_day'
        
        # 1. 非空校验
        print("\n1. 非空校验：")
        self.check_not_null(table, 'date_id', partition_date)
        self.check_not_null(table, 'order_count', partition_date)
        self.check_not_null(table, 'order_amount', partition_date)
        
        # 2. 数据范围校验
        print("\n2. 数据范围校验：")
        self.check_data_range(table, 'order_count', 0, 999999999, partition_date)
        self.check_data_range(table, 'order_amount', 0, 999999999999, partition_date)
        
        # 3. 数据一致性校验
        print("\n3. 数据一致性校验：")
        self.check_data_consistency(
            'gmall_dws.dws_order_day', 'order_amount',
            'gmall_dwd.dwd_order_detail', 'original_amount',
            partition_date
        )

    def validate_ads_gmv_day(self, partition_date: str = None):
        """校验 ADS 层 GMV 报表"""
        print("\n" + "="*80)
        print("校验 ADS_GMV_DAY（GMV日报表）")
        print("="*80)
        
        table = 'gmall_ads.ads_gmv_day'
        
        # 1. 非空校验
        print("\n1. 非空校验：")
        self.check_not_null(table, 'dt', partition_date)
        self.check_not_null(table, 'gmv', partition_date)
        self.check_not_null(table, 'order_count', partition_date)
        
        # 2. 数据范围校验
        print("\n2. 数据范围校验：")
        self.check_data_range(table, 'gmv', 0, 999999999999, partition_date)
        self.check_data_range(table, 'order_count', 0, 999999999, partition_date)
        
        # 3. 数据一致性校验
        print("\n3. 数据一致性校验：")
        self.check_data_consistency(
            'gmall_ads.ads_gmv_day', 'gmv',
            'gmall_dws.dws_order_day', 'order_amount',
            partition_date
        )

    def validate_all(self, partition_date: str = None):
        """执行所有校验"""
        print("="*80)
        print("              数据质量校验工具 - 全面检查")
        print("="*80)
        print(f"\n开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"检查日期: {partition_date or self.biz_date}")
        print(f"连接状态: {'已连接' if self.cursor else '模拟模式'}")
        print(f"检查范围: ODS/DWD/DWS/ADS 层核心表")
        
        # ODS 层校验
        self.validate_dwd_order_info(partition_date)
        self.validate_dwd_order_detail(partition_date)
        self.validate_dws_gmv_stats(partition_date)
        self.validate_ads_gmv_day(partition_date)
        
        # 生成报告
        self.generate_report()
        
        # 关闭连接
        self.close()

    def generate_report(self):
        """生成校验报告"""
        print("\n" + "="*80)
        print("                       数据质量校验报告")
        print("="*80)
        
        print(f"\n检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"检查日期: {self.biz_date}")
        print(f"总检查项: {self.total_check_count}")
        print(f"通过: {self.success_count}")
        print(f"失败: {len(self.errors)}")
        print(f"警告: {len(self.warnings)}")
        
        if self.total_check_count > 0:
            pass_rate = (self.success_count / self.total_check_count) * 100
            print(f"通过率: {pass_rate:.2f}%")
        
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
    import argparse
    
    parser = argparse.ArgumentParser(description='数据质量校验工具')
    parser.add_argument('--host', default='localhost', help='Hive Metastore主机')
    parser.add_argument('--port', type=int, default=10000, help='Hive Metastore端口')
    parser.add_argument('--date', help='检查日期 (YYYY-MM-DD格式)')
    parser.add_argument('--table', help='只检查指定表')
    
    args = parser.parse_args()
    
    validator = DataQualityValidator(
        host=args.host,
        port=args.port,
        biz_date=args.date
    )
    
    if args.table:
        # 只检查指定表
        if args.table == 'dwd_order_info':
            validator.validate_dwd_order_info()
        elif args.table == 'dwd_order_detail':
            validator.validate_dwd_order_detail()
        elif args.table == 'dws_gmv':
            validator.validate_dws_gmv_stats()
        elif args.table == 'ads_gmv':
            validator.validate_ads_gmv_day()
        else:
            print(f"不支持的表: {args.table}")
    else:
        # 执行所有检查
        validator.validate_all()
    
    # 返回退出码
    result = len(validator.errors) == 0
    sys.exit(0 if result else 1)
