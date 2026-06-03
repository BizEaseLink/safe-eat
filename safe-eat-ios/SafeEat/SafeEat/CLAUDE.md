# SafeEat iOS — 代码库指南

## 产品定位

SafeEat 是面向高血糖、高血压、高血脂、控体重与家庭健康管理人群的健康饮食辅助 iOS App。
核心流程：拍照识别食物 → AI 分析营养成分与健康风险 → 评分 + 推荐等级 + 建议展示。
支持多语言（中/英）、会员分层（Free/Lite/Pro/Premium）、广告变现（友盟 SDK）。

## 技术栈

- Swift + SwiftUI，@Observable 架构（iOS 17+）
- 自定义字体 ChillRoundF（Regular/Semibold/Bold），通过 SafeEatFont 注册和映射
- 友盟 SDK：开屏广告、插屏、激励视频、浮窗、Banner、原生广告
- Apple IAP：会员订阅验证
- 后端 API：`/v1/apps/:appCode/` 路径格式，全局拦截器 `{status, data, message}`

## 目录结构

```
SafeEat/
  SafeEatApp.swift           — App 入口，启动流程：Logo动画 → 开屏广告 → 主页面
  ContentView.swift          — 根视图：未启动=ProgressView，未完成引导=OnboardingView，引导后需登录=LoginView，否则=MainTabView
  App/
    MainTabView.swift         — 三 Tab：首页(Home)/菜单(Menu)/个人(Profile)
    AppStore.swift            — 全局状态 @Observable：session/profile/quota/localHistory/errorMessage

  Features/
    Auth/                     — 登录(LoginView)、引导(OnboardingView)
    Home/                     — 首页(ScanHomeView)、相机(CameraCaptureView)、配额(QuotaStatusBar/QuotaExceededSheet)、广告奖励(AdRewardResultSheet)、注册奖励(SignupBonusSheet)
    Result/                   — 识别结果(ResultView)：正反翻转卡，评分圆环+推荐等级+过敏原+饱腹感+10层营养 Section（Paywall 门控），AI 建议
    Menu/                     — 菜单周视图(MenuWeekView)、每日表现(DailyPerformanceCard)、餐段(MealPeriodSection)
    History/                  — 历史记录：日/周/月视图 + 服务端列表 + 详情
    Profile/                  — 个人中心、会员购买(MembershipPurchaseView)、兑换码(RedeemCodeSheet)、语言设置、健康目标、订单历史等

  Shared/
    Utils/
      SafeEatTheme.swift      — 颜色 token：primaryDeep(#1D5D43)、primary(#2E7D5A)、primarySoft(#DFF2E7)、accent(#B9DEC4)、success/warning/danger、动态 Light/Dark textPrimary/textSecondary/line
      SafeEatFont.swift       — 字体系统：ChillRoundF 三权重，textStyle()/custom()/uiFont() API
      SafeEatAppearance.swift — UIKit 全局外观配置（TabBar/NavBar/Button/TextField）
      SafeEatPageChrome.swift — 滚动导航栏、返回按钮、日期标题、空状态
      SafeEatMainGradientBackground.swift — 首页/结果页渐变背景
      BackgroundRemovalService.swift — 食物图片背景去除 + 预览图生成
    Components/
      AppLogoView.swift       — 应用 Logo（xcassets AppLogo，Light/Dark 适配）
      SafeEatSurfaceCard.swift — 通用卡片组件
      SafeEatSettingsSheetContainer.swift — 设置类 Sheet 容器
      LoginPromptSheet.swift  — 登录引导弹窗
      MembershipPromptSheet.swift — 会员引导弹窗
      NewUserWelcomeSheet.swift — 新用户欢迎
      QuotaExhaustedSheet.swift — 额度耗尽弹窗
      ForceUpdateSheet.swift  — 强制更新弹窗
      UpdateAvailableSheet.swift — 普通更新弹窗
      EmptyStateView.swift    — 空状态占位
      LottieLoadingView.swift — Lottie 加载动画
      AsyncRecognitionStickerView.swift — 异步识别贴纸
    Models/
      RecognitionModels.swift — 核心数据结构：RecognitionRecord、NutritionMetrics(v3)、Nutrients/Vitamins/Minerals、HealthImpact/MetricImpact/RiskFact/AIExplanation、Allergens/DietaryInfo/Preparation/IngredientBreakdown
      UserModels.swift        — UserProfile、AuthSession、DailyQuotaSnapshot、MembershipPlan 等
      AppVersionModels.swift  — AppVersionCheckResponse
      AuthModels.swift        — 认证相关模型
      DisclosureModels.swift  — 披露/隐私条款
      AdConfigModel.swift     — 广告配置
      LocalHistoryItem.swift  — 本地历史记录模型
    Network/
      SafeEatAPI.swift        — 网络层：所有 API 调用，拦截器格式解析，分页支持，multipart 上传
    Storage/
      LocalHistoryStore.swift — 本地历史持久化
      AuthSessionStore.swift  — 认证 session 存储
    Services/
      AppVersionStore.swift   — 版本更新检查与弹窗触发
    Localization/
      AppLocalization.swift   — SafeEatL10n.text()/format()，L10nKey 常量
    Config/
      AppConfig.swift         — appCode/apiBaseURL/appStoreID 等配置

  ThirdParty/                  — UMeng 广告 SDK 集成
```

## 设计系统

### 颜色 (SafeEatTheme)

| Token | Hex | 用途 |
|-------|-----|------|
| primaryDeep | #1D5D43 | 主按钮渐变起点、深色品牌色 |
| primary | #2E7D5A | 主按钮渐变终点、Tab选中、全局 tint |
| primarySoft | #DFF2E7 | 渐变背景光斑、Chip 背景 |
| accent | #B9DEC4 | 辅助色 |
| success | #3D9B62 | 推荐/正面/绿灯 |
| warning | #D6A545 | 谨慎/评分 60-79 |
| danger | #C95B44 | 避免/风险/红灯 |
| textPrimary | dynamic(L:#19342C, D:#F3F6F4) | 正文 |
| textSecondary | dynamic(L:#60746D, D:#C3CBC8) | 辅助文字 |
| line | dynamic(L:#19342C@10%, D:#FFFFFF@8%) | 分割线/卡片描边 |

### 字体 (SafeEatFont)

- 品牌字体：ChillRoundF（Regular/Semibold/Bold）
- API：`SafeEatFont.textStyle(.headline)` / `SafeEatFont.custom(size, relativeTo:, weight:)`
- 所有页面必须用 SafeEatFont，不用系统 .font()
- View modifier：`.safeEatBaseFont()` 设置全局基础字体

### 组件模式

- **卡片**：SafeEatSurfaceCard — 白色/深色半透明填充 + 描边 + 圆角 26
- **主按钮**：LinearGradient(primaryDeep → primary) + 圆角 18-20 + 阴影
- **次按钮**：白色半透明填充 + 描边 + 圆角 18-20
- **Chip/Capsule**：颜色 opacity(0.12~0.18) 背景 + Capsule clipShape + 描边
- **渐变背景**：LinearGradient(top→bottom) + RadialGradient(左上/右下光斑)
- **滚动导航**：SafeEatScrollNavChrome / SafeEatTopBackChrome — ultraThinMaterial + 渐变遮罩
- **Sheet 容器**：SafeEatSettingsSheetContainer — 标题+副标题+内容区

### Dark Mode

所有颜色和组件均支持 Light/Dark，通过 `@Environment(\.colorScheme)` 动态调整：
- 背景：近白→近黑，光斑 opacity 下降
- 卡片：白色低 opacity→白色极低 opacity
- 描边：line→白色低 opacity
- 按钮：白色高 opacity→白色极低 opacity

## 关键业务逻辑

### 启动流程
Logo动画(1.67s) → 检查开屏广告(非付费+配置启用) → 开屏广告(5s超时保护) → ContentView → 版本检查(强制/普通更新弹窗)

### 拍照识别流程
ScanHomeView → CameraCaptureView(裁剪) → 上传图片(createRecognition) → 获取详情(getRecognition) → 生成预览图(背景去除+建议等级色调) → 本地记录 → ResultView(导航跳转)

### 会员分层与 Paywall
- Free：基础营养素(S1) + 过敏原 contains + 评分/推荐/建议摘要
- Lite：+ 详细营养素(S2-S6) + AI 摘要
- Pro：+ 饮食信息(S8) + 制备方式(S9) + mayContain + AI 详细建议
- Premium：+ 成分分解(S10) + 健康提示 + AI 全量

### 额度系统
- 每日识别次数限制（Free tier）
- 激励视频看广告领奖励（rewardVideo）
- 额度耗尽弹窗(QuotaExceededSheet/QuotaExhaustedSheet)

## 重要注意事项

- 代码中中文注释为主，变量/函数名英文
- API 所有请求路径包含 `AppConfig.appCode`
- RecognitionRecord 有两套营养数据：v3 NutritionMetrics（优先）和扁平 NutritionSnapshot（降级）
- 10 层营养 Section 通过 PaywallOverlayView 门控，按 tier 可见/部分可见/完全遮罩
- 版本更新通过 AppVersionStore + NotificationCenter 触发 ContentView 弹窗
- 广告配置通过 AdConfigStore 管理，从后端拉取，2小时定时刷新