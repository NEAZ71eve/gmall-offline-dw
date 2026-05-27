# ODS 层表结构定义

## 概述
ODS（Operational Data Store）层是数据仓库的原始数据层，用于存储从业务系统直接抽取的原始数据。本层数据保持与源系统一致的结构，不做任何清洗和转换。

## ODS 层表列表

### 1. ods_user_info（用户信息表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 用户ID |
| login_name | string | 登录名 |
| nick_name | string | 昵称 |
| name | string | 姓名 |
| phone_num | string | 手机号 |
| email | string | 邮箱 |
| head_img | string | 头像URL |
| user_level | string | 用户等级 |
| birthday | string | 生日 |
| gender | string | 性别 |
| create_time | string | 创建时间 |
| operate_time | string | 操作时间 |
| status | string | 状态 |

### 2. ods_sku_info（商品SKU表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | SKU ID |
| spu_id | string | SPU ID |
| price | decimal(16,2) | 价格 |
| sku_name | string | SKU名称 |
| sku_desc | string | SKU描述 |
| weight | decimal(16,2) | 重量 |
| tm_id | string | 品牌ID |
| category3_id | string | 三级分类ID |
| create_time | string | 创建时间 |

### 3. ods_spu_info（商品SPU表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | SPU ID |
| spu_name | string | SPU名称 |
| description | string | 描述 |
| category3_id | string | 三级分类ID |
| tm_id | string | 品牌ID |

### 4. ods_base_trademark（品牌表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 品牌ID |
| tm_name | string | 品牌名称 |
| logo_url | string | 品牌LOGO URL |

### 5. ods_base_category1（一级分类表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 一级分类ID |
| name | string | 分类名称 |

### 6. ods_base_category2（二级分类表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 二级分类ID |
| name | string | 分类名称 |
| category1_id | string | 一级分类ID |

### 7. ods_base_category3（三级分类表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 三级分类ID |
| name | string | 分类名称 |
| category2_id | string | 二级分类ID |

### 8. ods_order_info（订单表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 订单ID |
| consignee | string | 收货人 |
| consignee_tel | string | 收货人电话 |
| total_amount | decimal(16,2) | 总金额 |
| order_status | string | 订单状态 |
| user_id | string | 用户ID |
| payment_way | string | 支付方式 |
| delivery_address | string | 收货地址 |
| order_comment | string | 订单备注 |
| out_trade_no | string | 外部交易号 |
| trade_body | string | 交易主体 |
| create_time | string | 创建时间 |
| operate_time | string | 操作时间 |
| expire_time | string | 过期时间 |
| tracking_no | string | 物流单号 |
| parent_order_id | string | 父订单ID |
| img_url | string | 图片URL |
| province_id | string | 省份ID |
| benefit_reduce_amount | decimal(16,2) | 优惠金额 |
| original_total_amount | decimal(16,2) | 原始总金额 |
| feight_fee | decimal(16,2) | 运费 |

### 9. ods_order_detail（订单明细表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 订单明细ID |
| order_id | string | 订单ID |
| sku_id | string | SKU ID |
| sku_name | string | SKU名称 |
| img_url | string | 商品图片URL |
| order_price | decimal(16,2) | 订单价格 |
| sku_num | bigint | 购买数量 |
| create_time | string | 创建时间 |
| source_type | string | 来源类型 |
| source_id | string | 来源ID |

### 10. ods_payment_info（支付表）
| 字段名 | 数据类型 | 说明 |
|--------|----------|------|
| id | string | 支付ID |
| out_trade_no | string | 外部交易号 |
| order_id | string | 订单ID |
| user_id | string | 用户ID |
| payment_type | string | 支付类型 |
| trade_no | string | 交易号 |
| total_amount | decimal(16,2) | 支付金额 |
| subject | string | 支付主题 |
| payment_status | string | 支付状态 |
| create_time | string | 创建时间 |
| callback_time | string | 回调时间 |
| callback_content | string | 回调内容 |

## 数据文件格式

### 存储位置
`/warehouse/gmall/ods/`

### 文件格式
- 格式：文本文件（Tab分隔）
- 编码：UTF-8
- 分隔符：Tab（\t）
- 空值表示：\N

### 示例文件名
- `user_info`
- `order_info`
- `order_detail`

## 数据加载时间
- 增量加载：每日凌晨
- 全量加载：首次加载时

## 数据质量规则
1. 数据直接来自业务库，不做任何转换
2. 保留原始数据的完整性
3. 使用 \N 表示空值
4. 字段顺序与源表保持一致

---

**更新时间**：2026-05-27  
**数据记录数**：
- user_info: 20
- sku_info: 4
- spu_info: 3
- base_trademark: 5
- base_category1: 4
- base_category2: 6
- base_category3: 8
- order_info: 50
- order_detail: 102
- payment_info: 0
