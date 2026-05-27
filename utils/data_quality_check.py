#!/usr/bin/env python3
"""
数据质量监控脚本
检查数据仓库各层数据质量，生成质量报告
"""

from datetime import datetime, timedelta
import sys

class DataQualityChecker:
    def __init__(self):
        self.hdfs_cmd = '/usr/local/hadoop/bin/hdfs dfs'
        self.quality_issues = []
        self.quality_stats = []

    def check_ods_layer(self):
        """检查 ODS 层数据质量"""
        print("\n【ODS层数据质量检查】")
        print("-" * 80)

        tables = [
            ('ods_user_info', '用户表'),
            ('ods_order_info', '订单表'),
            ('ods_order_detail', '订单明细表'),
            ('ods_sku_info', '商品表'),
        ]

        for table, name in tables:
            print(f"\n检查 {name} ({table})...")

            try:
                # 检查是否有数据
                result = self.run_hdfs_cmd(f'-ls /warehouse/gmall/ods/{table} 2>/dev/null')
                if 'No such file' in result or not result.strip():
                    print(f"  ⚠️  表不存在或为空")
                    self.quality_issues.append(f"{table}: 表不存在或为空")
                    self.quality_stats.append((table, 0, 'NO_DATA'))
                    continue

                # 检查数据文件大小
                file_result = self.run_hdfs_cmd(f'-du -h /warehouse/gmall/ods/{table} 2>/dev/null')
                if file_result and 'No such' not in file_result:
                    total_size = 0
                    for line in file_result.strip().split('\n'):
                        parts = line.split()
                        if parts:
                            try:
                                size = parts[0]
                                if 'K' in size:
                                    total_size += float(size.replace('K', ''))
                                elif 'M' in size:
                                    total_size += float(size.replace('M', '')) * 1024
                                elif 'G' in size:
                                    total_size += float(size.replace('G', '')) * 1024 * 1024
                            except:
                                pass

                    print(f"  ✓ 数据文件总大小: {total_size:.2f} KB")

                    # 检查数据质量规则
                    rules_passed = []

                    # 规则1: 数据文件大小 > 0
                    if total_size > 0:
                        rules_passed.append("文件大小正常")
                    else:
                        self.quality_issues.append(f"{table}: 文件大小为0")

                    # 规则2: 检查数据完整性（使用 Hive）
                    # 如果有 Hive 环境，可以添加更详细的检查

                    print(f"  ✓ 检查通过: {', '.join(rules_passed)}")
                    self.quality_stats.append((table, total_size, 'OK'))

            except Exception as e:
                print(f"  ✗ 检查失败: {e}")
                self.quality_issues.append(f"{table}: 检查失败 - {e}")
                self.quality_stats.append((table, 0, 'ERROR'))

    def check_dim_layer(self):
        """检查 DIM 层数据质量"""
        print("\n\n【DIM层数据质量检查】")
        print("-" * 80)

        tables = [
            ('dim_user', '用户维度表'),
            ('dim_sku', '商品维度表'),
            ('dim_time', '日期维度表'),
        ]

        for table, name in tables:
            print(f"\n检查 {name} ({table})...")

            try:
                result = self.run_hdfs_cmd(f'-ls /warehouse/gmall/dim/{table} 2>/dev/null')
                if 'No such file' in result or not result.strip():
                    print(f"  ⚠️  表不存在或为空")
                    self.quality_issues.append(f"{table}: 表不存在或为空")
                    self.quality_stats.append((table, 0, 'NO_DATA'))
                    continue

                print(f"  ✓ 表存在")
                self.quality_stats.append((table, 1, 'OK'))

            except Exception as e:
                print(f"  ✗ 检查失败: {e}")
                self.quality_issues.append(f"{table}: 检查失败 - {e}")
                self.quality_stats.append((table, 0, 'ERROR'))

    def check_dwd_layer(self):
        """检查 DWD 层数据质量"""
        print("\n\n【DWD层数据质量检查】")
        print("-" * 80)

        tables = [
            ('dwd_order_detail', '订单明细事实表'),
            ('dwd_order_info', '订单事实表'),
        ]

        for table, name in tables:
            print(f"\n检查 {name} ({table})...")

            try:
                result = self.run_hdfs_cmd(f'-ls /warehouse/gmall/dwd/{table} 2>/dev/null')
                if 'No such file' in result or not result.strip():
                    print(f"  ⚠️  表不存在或为空")
                    self.quality_issues.append(f"{table}: 表不存在或为空")
                    self.quality_stats.append((table, 0, 'NO_DATA'))
                    continue

                print(f"  ✓ 表存在")

                # 检查分区
                partitions = self.run_hdfs_cmd(f'-ls /warehouse/gmall/dwd/{table}/dt=* 2>/dev/null')
                partition_count = len([p for p in partitions.split('\n') if 'dt=' in p])
                print(f"  ✓ 分区数: {partition_count}")

                if partition_count == 0:
                    self.quality_issues.append(f"{table}: 无有效分区")

                self.quality_stats.append((table, partition_count, 'OK'))

            except Exception as e:
                print(f"  ✗ 检查失败: {e}")
                self.quality_issues.append(f"{table}: 检查失败 - {e}")
                self.quality_stats.append((table, 0, 'ERROR'))

    def check_dws_layer(self):
        """检查 DWS 层数据质量"""
        print("\n\n【DWS层数据质量检查】")
        print("-" * 80)

        tables = [
            ('dws_gmv_stats', 'GMV统计表'),
            ('dws_user_stats', '用户统计表'),
        ]

        for table, name in tables:
            print(f"\n检查 {name} ({table})...")

            try:
                result = self.run_hdfs_cmd(f'-ls /warehouse/gmall/dws/{table} 2>/dev/null')
                if 'No such file' in result or not result.strip():
                    print(f"  ⚠️  表不存在或为空")
                    self.quality_issues.append(f"{table}: 表不存在或为空")
                    self.quality_stats.append((table, 0, 'NO_DATA'))
                    continue

                print(f"  ✓ 表存在")
                self.quality_stats.append((table, 1, 'OK'))

            except Exception as e:
                print(f"  ✗ 检查失败: {e}")
                self.quality_issues.append(f"{table}: 检查失败 - {e}")
                self.quality_stats.append((table, 0, 'ERROR'))

    def check_ads_layer(self):
        """检查 ADS 层数据质量"""
        print("\n\n【ADS层数据质量检查】")
        print("-" * 80)

        tables = [
            ('ads_gmv_day', 'GMV日报表'),
            ('ads_sku_sales_rank', '商品销售排行表'),
            ('ads_user_retention', '用户留存表'),
        ]

        for table, name in tables:
            print(f"\n检查 {name} ({table})...")

            try:
                result = self.run_hdfs_cmd(f'-ls /warehouse/gmall/ads/{table} 2>/dev/null')
                if 'No such file' in result or not result.strip():
                    print(f"  ⚠️  表不存在或为空")
                    self.quality_issues.append(f"{table}: 表不存在或为空")
                    self.quality_stats.append((table, 0, 'NO_DATA'))
                    continue

                print(f"  ✓ 表存在")
                self.quality_stats.append((table, 1, 'OK'))

            except Exception as e:
                print(f"  ✗ 检查失败: {e}")
                self.quality_issues.append(f"{table}: 检查失败 - {e}")
                self.quality_stats.append((table, 0, 'ERROR'))

    def run_hdfs_cmd(self, cmd):
        """执行 HDFS 命令"""
        import subprocess
        try:
            result = subprocess.run(
                f'{self.hdfs_cmd} {cmd}',
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout
        except:
            return ""

    def generate_report(self):
        """生成质量报告"""
        print("\n\n" + "=" * 80)
        print("                            数据质量报告")
        print("=" * 80)
        print(f"\n检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"检查范围: ODS/DIM/DWD/DWS/ADS")

        # 统计摘要
        print("\n【统计摘要】")
        total = len(self.quality_stats)
        ok_count = len([s for s in self.quality_stats if s[2] == 'OK'])
        error_count = len([s for s in self.quality_stats if s[2] == 'ERROR'])
        no_data_count = len([s for s in self.quality_stats if s[2] == 'NO_DATA'])

        print(f"  总表数: {total}")
        print(f"  ✓ 正常: {ok_count}")
        print(f"  ✗ 错误: {error_count}")
        print(f"  ⚠️  无数据: {no_data_count}")

        # 问题列表
        if self.quality_issues:
            print("\n【问题列表】")
            for i, issue in enumerate(self.quality_issues, 1):
                print(f"  {i}. {issue}")
        else:
            print("\n✓ 所有数据质量检查通过！")

        # 详细统计
        print("\n【详细统计】")
        print(f"{'表名':<30} {'状态':<15} {'说明'}")
        print("-" * 70)
        for table, value, status in self.quality_stats:
            status_text = {
                'OK': '✓ 正常',
                'ERROR': '✗ 错误',
                'NO_DATA': '⚠️ 无数据'
            }.get(status, status)

            if status == 'OK':
                desc = f'数据量: {value}'
            elif status == 'ERROR':
                desc = '检查失败'
            else:
                desc = '表为空'

            print(f"{table:<30} {status_text:<15} {desc}")

        # 建议
        print("\n【改进建议】")
        if error_count > 0:
            print("  1. 检查错误表的 ETL 流程，确保数据正确处理")
            print("  2. 查看日志文件，定位具体错误原因")
        if no_data_count > 0:
            print("  1. 检查数据源是否正常")
            print("  2. 确认 ETL 任务是否正常执行")
        if ok_count == total:
            print("  ✓ 数据质量良好，继续保持！")

        print("\n" + "=" * 80)

    def run_all_checks(self):
        """运行所有检查"""
        print("=" * 80)
        print("                     数据仓库数据质量检查工具")
        print("=" * 80)

        self.check_ods_layer()
        self.check_dim_layer()
        self.check_dwd_layer()
        self.check_dws_layer()
        self.check_ads_layer()

        self.generate_report()

if __name__ == '__main__':
    checker = DataQualityChecker()
    checker.run_all_checks()
