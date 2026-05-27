# Apache Superset 可视化平台使用指南

## 一、Superset 简介

Apache Superset 是一个现代化的企业级商业智能（BI）Web 应用，具有以下特点：
- 开源免费，支持多种数据源
- 直观的可视化界面
- 丰富的图表类型
- 支持 SQL 查询
- 权限管理和多用户协作

---

## 二、快速部署

### 方式1：使用部署脚本（推荐）

```bash
cd /mnt/d/s/作业/superset
chmod +x install_superset.sh
./install_superset.sh
```

按照提示选择操作：
- `1` - 完整安装（首次部署）
- `3` - 仅启动服务（已安装）
- `5` - 完整部署

### 方式2：Docker 部署

```bash
# 拉取镜像
docker pull apache/superset

# 启动容器
docker run -d -p 8088:8088 \
  -e SUPERSET_CONFIG_PATH=/app/superset_config.py \
  -v /mnt/d/s/作业/superset:/app \
  --name superset \
  apache/superset
```

---

## 三、访问 Superset

部署完成后，访问：
- **地址**：http://localhost:8088
- **用户名**：admin
- **密码**：admin123

---

## 四、配置数据源

### 步骤1：连接 Hive 数据库

1. 登录 Superset
2. 点击顶部菜单 **Data** → **Databases**
3. 点击 **+ Database** 按钮
4. 填写配置：

```
Database Name: Hive_Gmall_Data
SQLAlchemy URI: hive://hadoop@localhost:10000/gmall
```

5. 点击 **Test Connection** 测试连接
6. 连接成功后，点击 **Connect**

### 步骤2：创建数据集

1. 点击顶部菜单 **Data** → **Datasets**
2. 点击 **+ Dataset** 按钮
3. 选择数据库和数据表：

**推荐创建的数据集**：

| 数据库 | 数据表 | 说明 |
|-------|--------|------|
| Hive_Gmall_Data | gmall_ads.ads_gmv_day | GMV日报 |
| Hive_Gmall_Data | gmall_ads.ads_sku_sales_rank | 商品销售排行 |
| Hive_Gmall_Data | gmall_ads.ads_user_retention | 用户留存 |
| Hive_Gmall_Data | gmall_ads.ads_conversion_rate | 转化率分析 |
| Hive_Gmall_Data | gmall_dws.dws_gmv_stats | GMV统计 |
| Hive_Gmall_Data | gmall_dws.dws_user_stats | 用户统计 |
| Hive_Gmall_Data | gmall_dwd.dwd_order_detail | 订单明细 |
| Hive_Gmall_Data | gmall_dim.dim_sku | 商品维度 |

或使用脚本自动配置：

```bash
cd /mnt/d/s/作业/superset
python create_datasets.py
```

---

## 五、创建图表

### 示例1：GMV趋势折线图

1. 点击顶部菜单 **Charts**
2. 点击 **+ Chart**
3. 选择数据集：`ads_gmv_day`
4. 配置图表：

```
图表类型：Line Chart
时间列：日期 (date)
指标：
  - GMV (求和)
  - 订单数 (求和)
时间范围：最近7天
```

5. 点击 **Query** 查看数据
6. 点击 **Visualize** 生成图表
7. 保存图表，命名为 "GMV趋势"

### 示例2：商品销售排行柱状图

1. 新建图表，选择数据集：`ads_sku_sales_rank`
2. 配置图表：

```
图表类型：Bar Chart
维度：商品名称 (sku_name)
指标：
  - 销售额 (order_amount，求和)
排序：销售额降序
限制：Top 10
```

### 示例3：用户留存漏斗图

1. 新建图表，选择数据集：`ads_user_retention`
2. 配置图表：

```
图表类型：Funnel Chart
维度：留存天数 (retention_day)
指标：
  - 留存用户数 (retention_count，求和)
```

### 示例4：转化率仪表盘

1. 新建图表，选择数据集：`ads_conversion_rate`
2. 配置图表：

```
图表类型：Gauge Chart
指标：总体转化率
范围：0-100%
```

---

## 六、创建仪表板

### 步骤1：创建仪表板

1. 点击顶部菜单 **Dashboards**
2. 点击 **+ Dashboard**
3. 填写信息：

```
Name: 电商数据大屏
Description: 实时业务数据监控
Slug: ecommerce-dashboard
```

4. 点击 **Save**

### 步骤2：添加图表到仪表板

1. 打开创建的仪表板
2. 点击 **Edit Dashboard**
3. 点击 **+ Add Chart**
4. 选择要添加的图表
5. 调整图表大小和位置

### 推荐仪表板布局

```
┌────────────────────────────────────────────────────────────┐
│                    电商数据大屏                            │
├──────────────┬──────────────┬──────────────┬──────────────┤
│   今日GMV   │   今日订单   │   今日用户   │   转化率    │
│   ¥15,191   │    10单     │     5人     │    12%      │
├──────────────┴──────────────┴──────────────┴──────────────┤
│                    GMV趋势折线图                         │
│  [═══════════════════════════════════════════════]      │
│  1日  2日  3日  4日  5日  6日  7日                     │
├─────────────────────────────┬──────────────────────────────┤
│    商品销售排行柱状图       │      用户留存漏斗图         │
│  1. iPhone 15    3598     │      访问1000              │
│  2. MacBook Pro  3999     │      加购300                │
│  3. AirPods      1599     │      下单150                │
│  4. 小米14       199      │      支付120                │
└─────────────────────────────┴──────────────────────────────┘
```

---

## 七、预置图表SQL查询

项目中已包含所有业务报表的 SQL 查询，可直接复制使用：

**文件位置**：`/mnt/d/s/作业/superset/chart_queries.py`

**主要查询**：

1. **GMV统计**
   - GMV日报
   - GMV趋势
   - GMV周期统计

2. **商品分析**
   - 商品销售排行
   - 商品分类销售
   - 商品销售趋势

3. **用户分析**
   - 用户留存
   - 用户订单统计
   - 用户生命周期价值

4. **转化漏斗**
   - 转化率分析
   - 漏斗分析

5. **订单分析**
   - 订单状态分布
   - 订单时段分析
   - 订单金额分布

### 使用SQL查询

1. 点击顶部菜单 **SQL Lab**
2. 选择数据库：`Hive_Gmall_Data`
3. 在 SQL 编辑器中粘贴查询
4. 点击 **Run** 执行查询
5. 查看结果并可保存为新图表

---

## 八、高级功能

### 1. 定时刷新

1. 在图表或仪表板中，点击 **...** 菜单
2. 选择 **Set auto-refresh**
3. 设置刷新间隔（5分钟、10分钟、1小时等）

### 2. 权限管理

1. 点击顶部菜单 **Security**
2. 管理用户、角色和权限
3. 为不同角色分配数据集访问权限

### 3. 告警通知

1. 点击顶部菜单 **Alerts**
2. 创建告警规则
3. 配置通知方式（邮件、Slack等）

### 4. 数据导出

1. 在图表中点击 **...** 菜单
2. 选择 **Export as CSV** 或 **Export as Excel**

---

## 九、常见问题

### Q1: 连接 Hive 失败？

```bash
# 检查 Hive 服务状态
netstat -ano | grep 10000

# 安装 PyHive 依赖
pip install pyhive[hive] thrift-sasl

# 检查 PyHive 版本
pip show pyhive
```

### Q2: 图表加载很慢？

1. 减少查询数据量（添加时间过滤）
2. 启用缓存（Superset 配置中设置）
3. 使用采样数据

### Q3: 如何导出仪表板？

```bash
# 导出 JSON 配置
superset export_dashboards -f dashboard_export.zip

# 导入 JSON 配置
superset import_dashboards -f dashboard_export.zip
```

---

## 十、项目文件说明

```
superset/
├── superset_config.py      # Superset 配置文件
├── hive_connection.py      # Hive 连接配置
├── create_datasets.py      # 自动创建数据集脚本
├── chart_queries.py        # 预置图表 SQL 查询
└── install_superset.sh    # 安装部署脚本
```

---

## 十一、下一步

1. **部署 Superset**：运行安装脚本
2. **配置数据源**：连接 Hive 数据库
3. **创建图表**：使用预置 SQL 查询
4. **制作仪表板**：组装业务大屏
5. **配置定时任务**：自动刷新数据

---

**参考资源**：
- Superset 官方文档：https://superset.apache.org/docs/
- Superset GitHub：https://github.com/apache/superset
