# Safe-Eat Harmony API 对接说明

## 基础约定

- 基础地址：`http://{backend-host}:3000/api`
- 业务前缀：`/v1/safe-eat`
- 鉴权方式：`Authorization: Bearer {accessToken}`
- 识别接口字段：`multipart/form-data`，文件字段固定为 `image`
- 反馈接口字段：`multipart/form-data`，证据图字段固定为 `evidenceImage`
- 普通识别原图不会在服务端长期保存，客户端必须自行把识别结果图保存到本地或应用沙盒

## 登录流程

1. `POST /v1/safe-eat/auth/sms/send`
2. `POST /v1/safe-eat/auth/login`
3. 可选：`POST /v1/safe-eat/auth/huawei/bind`
4. Token 续期：`POST /v1/safe-eat/auth/refresh`

## 用户信息

- `GET /v1/safe-eat/me`
- `PATCH /v1/safe-eat/me/health-profile`

`health-profile` 可提交字段：

- `healthTags`
- `fitnessGoal`
- `avoidIngredients`
- `dietaryPreferences`

## 识别主链路

### 上传识别

`POST /v1/safe-eat/recognitions`

请求：

- `multipart/form-data`
- 文件字段：`image`

响应核心字段：

- `id`
- `recognizedName`
- `edibleStatus`
- `adviceLevel`
- `adviceText`
- `foodScore`
- `healthImpacts`
- `nutritionSnapshot`
- `reasons`
- `sourceType`
- `storedObjectId`

说明：

- `storedObjectId` 在普通识别场景下通常为 `null`
- `foodScore` 建议直接用于结果页评分显示
- `healthImpacts` 建议直接映射成结果页的分项风险标签

示例响应：

```json
{
  "id": "recognition-id",
  "recognizedName": "面条",
  "edibleStatus": "edible",
  "adviceLevel": "caution",
  "adviceText": "可以吃 面条，但建议控制份量。",
  "foodScore": 64,
  "healthImpacts": [
    {
      "condition": "high_blood_sugar",
      "label": "血糖管理",
      "level": "positive",
      "reason": "碳水负担相对温和，更适合作为控糖阶段的选择。"
    },
    {
      "condition": "high_blood_pressure",
      "label": "血压管理",
      "level": "risk",
      "reason": "存在偏重口或整体负担偏高的信号，建议谨慎食用。"
    }
  ],
  "nutritionSnapshot": {
    "calories": 138,
    "protein": 4.5,
    "fat": 1.8,
    "carbs": 27.2,
    "riskFlags": ["sodium_alert"]
  },
  "reasons": ["当前菜品可能偏重口或负担偏高，血压管理阶段建议谨慎食用。"],
  "sourceType": "external",
  "storedObjectId": null
}
```

### 获取识别详情

`GET /v1/safe-eat/recognitions/{id}`

响应除了识别结构化字段，还会返回：

```json
{
  "feedbackEvidence": {
    "hasEvidence": true,
    "reviewStatus": "approved_rare",
    "reviewSource": "system_timeout"
  }
}
```

说明：

- 这里不会返回服务端原图地址
- 若客户端本地图片丢失，应降级展示文本卡片或占位图

### 提交纠错反馈

`POST /v1/safe-eat/recognitions/{id}/feedback`

请求：

- `multipart/form-data`
- 文本字段：
  - `proposedName`
  - `comment`
- 文件字段：
  - `evidenceImage`

说明：

- 当识别记录没有服务端原图时，`evidenceImage` 必传
- 证据图只用于待审核和短时删除，不用于普通识别历史回显

## 本地历史记录建议

Harmony 端应把识别结果落到本地或应用沙盒，最少保存：

```json
{
  "recognitionId": "recognition-id",
  "localImageUri": "internal://safe-eat/history/2026-04-03/001.jpg",
  "recognizedName": "面条",
  "adviceLevel": "caution",
  "foodScore": 64,
  "createdAt": "2026-04-03T15:20:00.000Z"
}
```

## 商业化能力

### 套餐列表

`GET /v1/safe-eat/membership/plans`

### 创建订单

`POST /v1/safe-eat/orders`

请求体：

```json
{
  "planId": "plan-id",
  "channel": "wechat"
}
```

### 广告奖励补次

`POST /v1/safe-eat/ads/rewards/claim`

请求体：

```json
{
  "placementCode": "free-daily-reward",
  "proofToken": "client-generated-proof-token"
}
```

`proofToken` 需要客户端保证单次奖励唯一，不可重复使用。

## 回调说明

支付回调由服务端渠道通知，不需要 Harmony 端直接调用。

- `POST /v1/safe-eat/payments/callback/wechat`
- `POST /v1/safe-eat/payments/callback/alipay`

## 交互建议

- `adviceLevel` 建议映射为：
  - `recommended -> 推荐食用`
  - `caution -> 谨慎食用`
  - `avoid -> 不建议食用`
- 当 `edibleStatus=non_food` 时，前端直接展示非食物结果，不展示营养卡片。
- 当用户认为识别错误时，从结果页直达反馈页，并把本地图片作为 `evidenceImage` 回传。
- 历史页优先读取本地/沙盒图片，不要依赖服务端回传原图。
