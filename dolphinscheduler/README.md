# Apache DolphinScheduler 使用指南

## 一、DolphinScheduler 简介

Apache DolphinScheduler 是一个分布式易用、可视化的 DAG 工作流任务调度平台，主要解决复杂任务依赖关系所带来的问题。

**特点**：
- 分布式、去中心化的 DAG 工作流
- 友好的可视化界面
- 支持多种任务类型（Shell、Python、Hive、Spark、Flink 等）
- 强大的定时调度功能
- 完善的权限管理
- 支持邮件、短信等告警通知

---

## 二、快速部署

### 方式1：使用 Docker 部署（推荐）

```bash
# 拉取镜像
docker pull apache/dolphinscheduler-3.2.0

# 启动容器
docker run -d \
  --name dolphinscheduler \
  -p 12345:12345 \
  -p 3306:3306 \
  -e DATABASE_HOST=localhost \
  -e DATABASE_PORT=3306 \
  -e DATABASE_DB=dolphinscheduler \
  -e ZOOKEEPER_QUORUM=localhost:2181 \
  apache/dolphinscheduler-3.2.0
```

### 方式2：独立部署

```bash
# 下载 DolphinScheduler
wget https://downloads.apache.org/dolphinscheduler/3.2.0/apache-dolphinscheduler-3.2.0-bin.tar.gz

# 解压
tar -xzf apache-dolphinscheduler-3.2.0-bin.tar.gz
cd apache-dolphinscheduler-3.2.0-bin

# 修改配置
vim conf/dolphinscheduler_env.sh

# 启动服务
./bin/start-all.sh
```

---

## 三、访问 DolphinScheduler

部署完成后，访问：
- **地址**：http://localhost:12345
- **用户名**：admin
- **密码**：dolphinscheduler123

---

## 四、配置项目和工作流

### 步骤1：创建项目

1. 登录 DolphinScheduler
2. 点击左侧菜单 **项目管理**
3. 点击 **创建项目**
4. 填写信息：

```
项目名称: gmall-数据仓库
描述: 电商数仓每日ETL任务调度
```

5. 点击 **创建**

### 步骤2：上传工作流定义

项目创建后，可以：

**方式1：使用界面创建**

1. 进入项目
2. 点击 **工作流定义**
3. 点击 **创建工作流**
4. 从左侧拖拽任务节点
5. 配置任务参数
6. 保存工作流

**方式2：导入 JSON 配置**

项目已提供工作流 JSON 配置：
- 文件：`dolphinscheduler/workflow.json`

使用 API 导入：

```bash
# 导入工作流
curl -X POST "http://localhost:12345/dolphinscheduler/projects/{project_name}/import" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@workflow.json"
```

---

## 五、项目工作流说明

项目已配置完整的数据仓库 ETL 工作流，包含以下任务节点：

### 工作流：gmall_etl_daily（每日 ETL）

```
┌─────────────────┐
│  datax_user_info │ (DataX 同步用户数据)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  datax_order_info│ (DataX 同步订单数据)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│datax_order_detail│ (DataX 同步订单明细)
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│hive_dim│ │hive_dwd│
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         ▼
┌─────────────────┐
│   hive_dws     │ (Hive 汇总统计)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   hive_ads     │ (Hive 生成报表)
└─────────────────┘
```

### 任务节点详情

| 任务名称 | 类型 | 说明 |
|---------|------|------|
| datax_user_info | SHELL | DataX 同步用户数据 |
| datax_order_info | SHELL | DataX 同步订单数据 |
| datax_order_detail | SHELL | DataX 同步订单明细 |
| hive_dim | HIVE | 构建维度表（拉链表） |
| hive_dwd | HIVE | 数据清洗（去重、脱敏） |
| hive_dws | HIVE | 轻度汇总（GMV、用户统计） |
| hive_ads | HIVE | 生成应用报表 |

---

## 六、配置定时调度

### 步骤1：设置定时调度

1. 打开工作流定义
2. 点击 **定时** 按钮
3. 配置定时参数：

```
定时类型: Cron
Cron 表达式: 0 0 2 * * ?
描述: 每日凌晨2点执行
```

**常用 Cron 表达式**：

| 表达式 | 说明 |
|--------|------|
| `0 0 0 * * ?` | 每天午夜执行 |
| `0 0 2 * * ?` | 每天凌晨2点执行 |
| `0 0/30 * * * ?` | 每30分钟执行 |
| `0 0 0 * * MON-FRI` | 工作日午夜执行 |
| `0 0 0 1 * ?` | 每月1号执行 |

### 步骤2：选择定时策略

```
前端or后端: 前端
时区: Asia/Shanghai (GMT+8)
```

### 步骤3：启动定时

1. 点击 **启动定时**
2. 确认配置
3. 定时任务已生效

---

## 七、任务依赖配置

### 配置任务依赖

在同一个工作流中，可以配置任务间的依赖关系：

1. 拖拽两个任务节点到画布
2. 连接线从父任务指向子任务
3. 双击连接线，配置依赖类型：

```
依赖类型: 结束后执行
状态检查: 等待父任务完成
```

### 跨工作流依赖

如果需要跨工作流依赖：

1. 打开工作流 A
2. 添加 **子工作流** 任务节点
3. 选择工作流 B
4. 配置依赖条件

---

## 八、告警配置

### 配置告警组

1. 点击顶部菜单 **安全中心** → **告警组管理**
2. 点击 **创建告警组**
3. 填写信息：

```
告警组名称: 电商数仓告警组
告警方式:
  ☑ 邮件通知
  ☑ 短信通知（可选）
  ☑ 企业微信（可选）
```

### 配置告警规则

1. 打开工作流
2. 点击 **工作流操作** → **编辑**
3. 勾选 **失败告警**、**成功通知**
4. 选择告警组

### 内置告警类型

| 类型 | 说明 | 触发条件 |
|------|------|---------|
| 失败告警 | 任务执行失败时通知 | return_code != 0 |
| 超时告警 | 任务执行超时时通知 | 执行时间 > timeout |
| 成功通知 | 任务执行成功时通知 | return_code == 0 |

---

## 九、运维管理

### 查看任务执行记录

1. 点击顶部菜单 **项目管理**
2. 进入项目
3. 点击 **工作流实例**
4. 查看所有执行历史

### 查看任务日志

1. 进入工作流实例
2. 点击具体任务节点
3. 点击 **查看日志**

### 重跑任务

1. 进入工作流实例
2. 点击 **重跑** 按钮
3. 选择重跑范围：

```
☑ 从失败节点重跑
☑ 恢复失败节点
```

### 补数操作

用于补历史数据：

1. 点击 **补数**
2. 选择补数类型：

```
补数类型: 范围补数
日期范围: 2024-01-01 至 2024-01-31
```

---

## 十、权限管理

### 用户管理

1. 点击顶部菜单 **安全中心** → **用户管理**
2. 可执行操作：

```
- 创建用户
- 编辑用户
- 删除用户
- 修改密码
```

### 权限分配

1. 选中用户
2. 点击 **编辑权限**
3. 分配项目权限：

```
项目: gmall-数据仓库
权限: ☑ 编辑 ☑ 执行 ☑ 查看
```

---

## 十一、API 接口

DolphinScheduler 提供 RESTful API：

### 登录获取 Token

```bash
curl -X POST "http://localhost:12345/dolphinscheduler/login" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "admin",
    "userPassword": "dolphinscheduler123"
  }'
```

### 查询项目列表

```bash
curl -X GET "http://localhost:12345/dolphinscheduler/projects" \
  -H "token: {your_token}"
```

### 查询工作流实例

```bash
curl -X GET "http://localhost:12345/dolphinscheduler/projects/{project_id}/workflow-instances" \
  -H "token: {your_token}"
```

### 手动执行工作流

```bash
curl -X POST "http://localhost:12345/dolphinscheduler/projects/{project_id}/executors/start" \
  -H "Content-Type: application/json" \
  -H "token: {your_token}" \
  -d '{
    "scheduleTime": "2024-01-01 00:00:00",
    "failureStrategy": "CONTINUE",
    "warningType": "FAILURE"
  }'
```

---

## 十二、常见问题

### Q1: 工作流执行失败？

```bash
# 1. 查看任务日志
# 2. 检查数据源连接
# 3. 确认依赖任务是否成功
# 4. 检查资源是否充足
```

### Q2: 定时任务未执行？

```bash
# 1. 检查定时是否启动
# 2. 确认服务器时间正确
# 3. 检查调度器状态
# 4. 查看调度日志
```

### Q3: 任务执行很慢？

```bash
# 1. 检查资源使用情况
# 2. 优化 SQL 查询
# 3. 增加 Worker 分组
# 4. 调整并发参数
```

---

## 十三、项目文件说明

```
dolphinscheduler/
├── workflow.json             # ETL 工作流定义
├── submit_workflow.sh       # 工作流提交脚本
└── README.md                # 使用指南（本文件）
```

---

## 十四、下一步

1. **部署 DolphinScheduler**：运行部署脚本
2. **配置项目**：创建项目并导入工作流
3. **设置定时**：配置每日凌晨2点执行
4. **配置告警**：设置失败通知
5. **监控运维**：定期检查执行情况

---

**参考资源**：
- DolphinScheduler 官方文档：https://dolphinscheduler.apache.org/zh-cn/docs/3.2.0
- DolphinScheduler GitHub：https://github.com/apache/dolphinscheduler
