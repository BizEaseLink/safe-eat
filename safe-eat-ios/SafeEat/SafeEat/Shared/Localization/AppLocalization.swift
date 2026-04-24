import Foundation
import Combine
import UserNotifications

enum L10nKey {
    enum Brand {
        static let appName = "brand.app_name"
    }

    enum Language {
        static let optionChinese = "language.option.zh_hans"
        static let optionEnglish = "language.option.en"
    }

    enum Common {
        static let ok = "common.ok"
        static let notice = "common.notice"
        static let save = "common.save"
        static let saving = "common.saving"
        static let sendCode = "common.send_code"
        static let sending = "common.sending"
        static let `continue` = "common.continue"
        static let back = "common.back"
        static let cancel = "common.cancel"
        static let clear = "common.clear"
        static let delete = "common.delete"
        static let notSet = "common.not_set"
        static let unnamed = "common.unnamed"
        static let unknownFood = "common.unknown_food"
        static let scoreUnitFormat = "common.score_unit_format"
        static let adviceScoreFormat = "common.advice_score_format"
    }

    enum Advice {
        static let titleRecommended = "advice.title.recommended"
        static let titleCaution = "advice.title.caution"
        static let titleAvoid = "advice.title.avoid"
        static let titleEvaluate = "advice.title.evaluate"
        static let compactRecommended = "advice.compact.recommended"
        static let compactCaution = "advice.compact.caution"
        static let compactAvoid = "advice.compact.avoid"
        static let compactEvaluate = "advice.compact.evaluate"
        static let summaryRecommended = "advice.summary.recommended"
        static let summaryCaution = "advice.summary.caution"
        static let summaryAvoid = "advice.summary.avoid"
        static let summaryEvaluate = "advice.summary.evaluate"
    }

    enum Reminder {
        static let on = "reminder.on"
        static let off = "reminder.off"
        static let systemDenied = "reminder.system_denied"
        static let enableFailed = "reminder.enable_failed"
        static let enabled = "reminder.enabled"
        static let disabled = "reminder.disabled"
        static let entrySubtitle = "reminder.entry_subtitle"
        static let sheetTitle = "reminder.sheet.title"
        static let sheetSubtitle = "reminder.sheet.subtitle"
        static let toggleLabel = "reminder.sheet.toggle"
        static let timeLabel = "reminder.sheet.time_label"
        static let saveAction = "reminder.sheet.save"
        static let optionToday = "reminder.option.today"
        static let optionTomorrow = "reminder.option.tomorrow"
        static let summaryFormat = "reminder.summary.format"
        static let title = "reminder.notification.title"
        static let body = "reminder.notification.body"
    }

    enum Errors {
        static let avatarCompressionFailed = "error.avatar_compression_failed"
        static let saveOriginalFailed = "error.save_original_failed"
        static let saveHiddenOriginalFailed = "error.save_hidden_original_failed"
        static let localRecordMissing = "error.local_record_missing"
        static let localOriginalMissing = "error.local_original_missing"
        static let saveRotatedOriginalFailed = "error.save_rotated_original_failed"
        static let sessionExpired = "error.session_expired"
        static let invalidResponse = "error.invalid_response"
        static let invalidURL = "error.invalid_url"
        static let requestFailed = "error.request_failed"
        static let decodeFailed = "error.decode_failed"
        static let requestQuotaExceeded = "request.quota_exceeded"
    }

    enum Auth {
        static let onboardingEyebrow = "auth.onboarding.eyebrow"
        static let onboardingTitle = "auth.onboarding.title"
        static let onboardingBody = "auth.onboarding.body"
        static let onboardingCardOne = "auth.onboarding.card.one"
        static let onboardingCardTwo = "auth.onboarding.card.two"
        static let onboardingCardThree = "auth.onboarding.card.three"
        static let modePassword = "auth.mode.password"
        static let modeCode = "auth.mode.code"
        static let modeRegister = "auth.mode.register"
        static let appleAction = "auth.apple.action"
        static let passwordTitle = "auth.password.title"
        static let passwordSubtitle = "auth.password.subtitle"
        static let codeTitle = "auth.code.title"
        static let codeSubtitle = "auth.code.subtitle"
        static let registerTitle = "auth.register.title"
        static let registerSubtitle = "auth.register.subtitle"
        static let bindTitle = "auth.bind.title"
        static let bindSubtitle = "auth.bind.subtitle"
        static let phoneLabel = "auth.field.phone"
        static let codeLabel = "auth.field.code"
        static let passwordLabel = "auth.field.password"
        static let confirmPasswordLabel = "auth.field.confirm_password"
        static let actionLogin = "auth.action.login"
        static let actionCodeLogin = "auth.action.code_login"
        static let actionRegister = "auth.action.register"
        static let actionBind = "auth.action.bind"
        static let switchToPassword = "auth.switch.password"
        static let switchToCode = "auth.switch.code"
        static let switchToRegister = "auth.switch.register"
        static let switchBackWelcome = "auth.switch.welcome"
        static let smsHintFormat = "auth.sms.dev_code"
        static let passwordMismatch = "auth.error.password_mismatch"
        static let appleNameFallback = "auth.apple.name_fallback"
        static let goLogin = "auth.go_login"
        static let loginPromptMessage = "auth.login_prompt.message"
        static let orDivider = "auth.or_divider"
    }

    enum Onboarding {
        static let skip = "onboarding.skip"
        static let start = "onboarding.start"
        static let page1Title = "onboarding.page1.title"
        static let page1Body = "onboarding.page1.body"
        static let page2Title = "onboarding.page2.title"
        static let page2Body = "onboarding.page2.body"
        static let page3Title = "onboarding.page3.title"
        static let page3Body = "onboarding.page3.body"
    }

    enum Profile {
        static let title = "profile.root.title"
        static let heroDefaultName = "profile.hero.default_name"
        static let memberEntryTitle = "profile.member_entry.title"
        static let memberEntrySubtitle = "profile.member_entry.subtitle"
        static let memberEntryFormat = "profile.member_entry.format"
        static let infoSectionTitle = "profile.info.section_title"
        static let editTitle = "profile.edit.title"
        static let editSubtitle = "profile.edit.subtitle"
        static let preferenceTitle = "profile.preference.title"
        static let preferenceSubtitleDefault = "profile.preference.subtitle.default"
        static let systemSectionTitle = "profile.system.section_title"
        static let reminderTitle = "profile.system.reminder"
        static let languageTitle = "profile.system.language"
        static let languageSubtitle = "profile.system.language.subtitle"
        static let securityTitle = "profile.system.security"
        static let securitySubtitle = "profile.system.security.subtitle"
        static let cacheTitle = "profile.system.cache"
        static let cacheSubtitle = "profile.system.cache.subtitle"
        static let feedbackTitle = "profile.system.feedback"
        static let feedbackSubtitle = "profile.system.feedback.subtitle"
        static let updatesTitle = "profile.system.updates"
        static let updatesSubtitle = "profile.system.updates.subtitle"
        static let aboutTitle = "profile.about.title"
        static let aboutSubtitle = "profile.about.subtitle"
        static let rateTitle = "profile.rate.title"
        static let rateSubtitle = "profile.rate.subtitle"
        static let logout = "profile.logout"
        static let bmiLabel = "profile.bmi"
        static let editGroupTitle = "profile.edit.group_title"
        static let serviceGroupTitle = "profile.service.group_title"
        static let notLoggedInTitle = "profile.not_logged_in.title"
        static let notLoggedInMessage = "profile.not_logged_in.message"

        enum Edit {
            static let subtitle = "profile.edit.subtitle.long"
            static let avatarTitle = "profile.edit.avatar"
            static let avatarHint = "profile.edit.avatar_hint"
            static let choosePhoto = "profile.edit.choose_photo"
            static let basicSection = "profile.edit.basic_section"
            static let displayName = "profile.edit.display_name"
            static let gender = "profile.edit.gender"
            static let height = "profile.edit.height"
            static let weight = "profile.edit.weight"
            static let bmiHint = "profile.edit.bmi_hint"
        }

        enum Preference {
            static let subtitle = "profile.preference.subtitle.long"
            static let healthTags = "profile.preference.health_tags"
            static let fitnessGoal = "profile.preference.fitness_goal"
            static let healthTagsHint = "profile.preference.health_tags_hint"
            static let fitnessGoalHint = "profile.preference.fitness_goal_hint"
        }

        enum Language {
            static let title = "profile.language.title"
            static let subtitle = "profile.language.subtitle"
            static let sectionTitle = "profile.language.section_title"
        }

        enum Cache {
            static let title = "profile.cache.title"
            static let subtitle = "profile.cache.subtitle"
            static let currentSection = "profile.cache.current_section"
            static let localRecords = "profile.cache.local_records"
            static let cacheSize = "profile.cache.size"
            static let actionSection = "profile.cache.action_section"
            static let clearAction = "profile.cache.clear_action"
            static let confirmTitle = "profile.cache.confirm_title"
            static let confirmMessage = "profile.cache.confirm_message"
        }

        enum Security {
            static let title = "profile.security.title"
            static let subtitle = "profile.security.subtitle"
            static let session = "profile.security.session"
            static let sync = "profile.security.sync"
            static let cache = "profile.security.cache"
        }

        enum Feedback {
            static let title = "profile.feedback.title"
            static let subtitle = "profile.feedback.subtitle"
            static let deviceLabel = "profile.feedback.device_label"
            static let versionLabel = "profile.feedback.version_label"
            static let version = "profile.feedback.version"
            static let device = "profile.feedback.device"
            static let hint = "profile.feedback.hint"
        }

        enum Update {
            static let title = "profile.update.title"
            static let subtitle = "profile.update.subtitle"
            static let versionLabel = "profile.update.version_label"
            static let version = "profile.update.version"
            static let latest = "profile.update.latest"
        }

        enum About {
            static let title = "profile.about.page_title"
            static let subtitle = "profile.about.page_subtitle"
            static let appName = "profile.about.app_name"
            static let intro = "profile.about.intro"
            static let sectionTitle = "profile.about.section_title"
            static let sectionBody = "profile.about.section_body"
        }
    }

    enum Membership {
        static let title = "membership.purchase.title"
        static let subtitle = "membership.purchase.subtitle"
        static let noticeTitle = "membership.purchase.notice_title"
        static let promo = "membership.purchase.promo"
        static let heroTitle = "membership.purchase.hero_title"
        static let heroBody = "membership.purchase.hero_body"
        static let currentTier = "membership.purchase.current_tier"
        static let recommendedPlan = "membership.purchase.recommended_plan"
        static let sectionPlans = "membership.purchase.section_plans"
        static let sectionChannel = "membership.purchase.section_channel"
        static let dailyQuota = "membership.purchase.daily_quota"
        static let createOrder = "membership.purchase.create_order"
        static let orderCreated = "membership.purchase.order_created"
        static let cycleYearly = "membership.purchase.cycle_yearly"
        static let cycleMonthly = "membership.purchase.cycle_monthly"
        static let planNameFormat = "membership.purchase.plan_name_format"
        static let subtitlePro = "membership.purchase.plan_subtitle.pro"
        static let subtitleLite = "membership.purchase.plan_subtitle.lite"
        static let subtitleFree = "membership.purchase.plan_subtitle.free"
        static let badgeRecommended = "membership.purchase.badge.recommended"
        static let badgeAdvanced = "membership.purchase.badge.advanced"
        static let badgeDefault = "membership.purchase.badge.default"
    }

    enum Home {
        static let title = "home.title"
        static let brandPill = "home.brand_pill"
        static let promoTag = "home.promo.tag"
        static let promoValue = "home.promo.value"
        static let heroTagHealth = "home.hero.tag.health"
        static let heroTagHistory = "home.hero.tag.history"
        static let heroTitle = "home.hero.title"
        static let scanAction = "home.hero.scan_action"
        static let memberAction = "home.hero.member_action"
        static let recentTitle = "home.recent.title"
        static let emptyTitle = "home.recent.empty_title"
        static let emptyMessage = "home.recent.empty_message"
        static let loadingTitle = "home.loading.title"
        static let loadingSubtitle = "home.loading.subtitle"
        static let cameraPermissionTitle = "home.camera.permission_title"
        static let cameraPermissionBody = "home.camera.permission_body"
        static let cameraOpenSettings = "home.camera.open_settings"
        static let cameraGuide = "home.camera.guide"
        static let cameraStarting = "home.camera.starting"
        static let cameraPermissionOff = "home.camera.permission_off"
        static let cameraUnsupported = "home.camera.unsupported"
        static let cameraStartFailed = "home.camera.start_failed"
        static let cameraCaptureFailed = "home.camera.capture_failed"
        static let imageProcessFailed = "home.error.image_process_failed"
        static let loadingStepCrop = "home.loading.step_crop"
        static let loadingStepRemoveBackground = "home.loading.step_remove_bg"
        static let loadingStepSync = "home.loading.step_sync"
        static let localImagePrefix = "home.record.local_image_prefix"
        static let localImageFormat = "home.record.local_image_format"
        static let scoreFormat = "home.record.score_format"
        static let caloriesFormat = "home.record.calories_format"
        static let proteinFormat = "home.record.protein_format"
        static let carbsFormat = "home.record.carbs_format"
        static let detailAction = "home.record.detail_action"
        static let chipFriendly = "home.record.chip_friendly"
        static let chipPortion = "home.record.chip_portion"
        static let chipSwitch = "home.record.chip_switch"
        static let chipCheck = "home.record.chip_check"
        static let summaryRecommended = "home.record.summary.recommended"
        static let summaryCaution = "home.record.summary.caution"
        static let summaryAvoid = "home.record.summary.avoid"
        static let summaryUnknown = "home.record.summary.unknown"
        static let unknownFood = "home.record.unknown_food"
    }

    enum Menu {
        static let title = "menu.title"
        static let headerSubtitleFormat = "menu.header.subtitle_format"
        static let backToToday = "menu.week.back_to_today"
        static let heroEmptySummary = "menu.hero.empty_summary"
        static let heroFilledSummary = "menu.hero.filled_summary"
        static let metricToday = "menu.hero.metric_today"
        static let metricWeek = "menu.hero.metric_week"
        static let todayMarker = "menu.week.today_marker"
        static let dayRecordTitle = "menu.hero.day_record_title"
        static let dayRecordSubtitle = "menu.hero.day_record_subtitle"
        static let weekRecordTitle = "menu.hero.week_record_title"
        static let weekRecordSubtitle = "menu.hero.week_record_subtitle"
        static let dayRecordAction = "menu.daily.action"
        static let todayNoRecord = "menu.daily.no_record"
        static let weeklyOverview = "menu.weekly.overview"
        static let weeklyEmpty = "menu.weekly.empty"
        static let performanceExcellent = "menu.daily.performance.excellent"
        static let performanceMedium = "menu.daily.performance.medium"
        static let performanceNeedsImprove = "menu.daily.performance.needs_improve"
        static let performanceNoRecord = "menu.daily.performance.no_record"
        static let dailyTitleFormat = "menu.daily.title_format"
        static let statRecommendedFormat = "menu.daily.stat_recommended"
        static let statCautionFormat = "menu.daily.stat_caution"
        static let statAvoidFormat = "menu.daily.stat_avoid"
        static let weeklyStatRecommendedFormat = "menu.weekly.stat_recommended"
        static let weeklyStatCautionFormat = "menu.weekly.stat_caution"
        static let weeklyStatAvoidFormat = "menu.weekly.stat_avoid"
        static let weeklyEmptyRecommendedFormat = "menu.weekly.empty_stat_recommended"
        static let weeklyEmptyCautionFormat = "menu.weekly.empty_stat_caution"
        static let weeklyEmptyAvoidFormat = "menu.weekly.empty_stat_avoid"
        static let mealEmptyFormat = "menu.meal.empty_format"
        static let mealBreakfast = "menu.meal.breakfast"
        static let mealLunch = "menu.meal.lunch"
        static let mealDinner = "menu.meal.dinner"
    }

    enum Result {
        static let title = "result.title"
        static let analysisTitle = "result.analysis_title"
        static let nutritionAlertTitle = "result.risk.nutrition_alert_title"
        static let completenessTitle = "result.risk.completeness_title"
        static let completenessDetail = "result.risk.completeness_detail"
        static let scoreSectionTitle = "result.score.section_title"
        static let scoreLevelHigh = "result.score.level.high"
        static let scoreLevelMedium = "result.score.level.medium"
        static let scoreLevelLow = "result.score.level.low"
        static let statusInsufficient = "result.score.status_insufficient"
        static let incompleteSummary = "result.summary.incomplete"
        static let headerNote = "result.header_note"
        static let scoreLogicBody = "result.score.logic_body"
        static let scoreLogicTitle = "result.score.logic_title"
        static let scoreLogicFormat = "result.score.logic_format"
        static let scoreLogicHint = "result.score.logic_hint"
        static let medicalDisclaimer = "result.medical_disclaimer"
        static let metricCalories = "result.metric.calories"
        static let metricProtein = "result.metric.protein"
        static let metricFat = "result.metric.fat"
        static let metricCarbs = "result.metric.carbs"
        static let metricGramsUnit = "result.metric.grams_unit"
        static let actionContinue = "result.action.continue"
        static let actionRetake = "result.action.retake"
        static let actionFeedback = "result.action.feedback"
        static let detailSyncing = "result.detail.syncing"
        static let detailLocalOnly = "result.detail.local_only"
        static let nutritionSectionTitle = "result.section.nutrition"
        static let adviceSectionTitle = "result.section.advice"
        static let riskSectionTitle = "result.section.risk"
        static let imageMissing = "result.image_missing"
        static let missingTitle = "result.missing.title"
        static let missingMessage = "result.missing.message"
        static let reasonSeparator = "result.reason.separator"
    }

    enum Feedback {
        static let title = "feedback.title"
        static let replaceEvidenceTitle = "feedback.replace_evidence.title"
        static let sourceCamera = "feedback.replace_evidence.camera"
        static let sourceLibrary = "feedback.replace_evidence.library"
        static let status = "feedback.status"
        static let heroTitle = "feedback.hero.title"
        static let heroSubtitle = "feedback.hero.subtitle"
        static let heroBody = "feedback.hero.body"
        static let badgeCurrent = "feedback.badge.current"
        static let badgeCorrect = "feedback.badge.correct"
        static let inputPlaceholder = "feedback.input.placeholder"
        static let suggestionsTitle = "feedback.suggestions.title"
        static let noteTitle = "feedback.note.title"
        static let notePlaceholder = "feedback.note.placeholder"
        static let noteCountFormat = "feedback.note.count_format"
        static let auditTitle = "feedback.audit.title"
        static let auditBody = "feedback.audit.body"
        static let submit = "feedback.submit"
        static let thanks = "feedback.thanks"
        static let evidenceRequired = "feedback.error.evidence_required"
        static let suggestionSoba = "feedback.suggestion.soba"
        static let suggestionColdSoba = "feedback.suggestion.cold_soba"
        static let suggestionChilledSoba = "feedback.suggestion.chilled_soba"
    }

    enum History {
        static let dateShortFormat = "history.date.short_format"
        static let weekRangeFormat = "history.date.week_range_format"
        static let noRecords = "history.count.no_records"
        static let recordCountOne = "history.count.record_one"
        static let recordCountOther = "history.count.record_other"
        static let dayCountOne = "history.count.day_one"
        static let dayCountOther = "history.count.day_other"
        static let weekSummaryFormat = "history.week.summary_format"
        static let weekSectionSubtitleFormat = "history.week.section_subtitle_format"
        static let weekTitle = "history.week.title"
        static let dayEmptyTitle = "history.day.empty_title"
        static let dayEmptyMessage = "history.day.empty_message"
        static let weekEmptyTitle = "history.week.empty_title"
        static let weekEmptyMessage = "history.week.empty_message"
        static let weekdaySunday = "history.weekday.sunday"
        static let weekdayMonday = "history.weekday.monday"
        static let weekdayTuesday = "history.weekday.tuesday"
        static let weekdayWednesday = "history.weekday.wednesday"
        static let weekdayThursday = "history.weekday.thursday"
        static let weekdayFriday = "history.weekday.friday"
        static let weekdaySaturday = "history.weekday.saturday"
    }

    enum Sticker {
        static let swipeHint = "sticker.swipe_hint"
        static let resultTitle = "sticker.result_title"
    }

    enum User {
        static let unnamed = "user.unnamed"
        static let tierFreeTitle = "user.tier.free.title"
        static let tierLiteTitle = "user.tier.lite.title"
        static let tierProTitle = "user.tier.pro.title"
        static let tierFreeShort = "user.tier.free.short"
        static let tierLiteShort = "user.tier.lite.short"
        static let tierProShort = "user.tier.pro.short"
        static let genderMale = "user.gender.male"
        static let genderFemale = "user.gender.female"
        static let genderOther = "user.gender.other"
        static let healthPressure = "user.health.high_blood_pressure"
        static let healthSugar = "user.health.high_blood_sugar"
        static let healthLipids = "user.health.high_blood_lipids"
        static let healthWeightLoss = "user.health.weight_loss"
        static let healthMuscle = "user.health.muscle_gain"
        static let healthWellness = "user.health.general_wellness"
        static let goalBalanced = "user.goal.balanced"
        static let goalFatLoss = "user.goal.fat_loss"
        static let goalMuscle = "user.goal.muscle_gain"
        static let goalSugar = "user.goal.blood_sugar_control"
        static let goalCardio = "user.goal.cardiovascular_health"
        static let paymentAlipay = "user.payment.alipay"
        static let paymentWechat = "user.payment.wechat"
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case en = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .zhHans:
            return SafeEatL10n.text(L10nKey.Language.optionChinese)
        case .en:
            return SafeEatL10n.text(L10nKey.Language.optionEnglish)
        }
    }

    static var deviceDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .zhHans : .en
    }
}

enum ReminderStartDay: Int, CaseIterable, Identifiable {
    case today = 0
    case tomorrow = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today:
            return SafeEatL10n.text(L10nKey.Reminder.optionToday)
        case .tomorrow:
            return SafeEatL10n.text(L10nKey.Reminder.optionTomorrow)
        }
    }
}

enum SafeEatL10n {
    static func text(_ key: String) -> String {
        bundle(for: AppSettingsStore.shared.language)
            .localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: AppSettingsStore.shared.language.locale, arguments: arguments)
    }

    private static func bundle(for language: AppLanguage) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }
}

enum SafeEatHistoryL10n {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = SafeEatL10n.text(L10nKey.History.dateShortFormat)
        return formatter.string(from: date)
    }

    static func weekRange(start: Date, end: Date) -> String {
        SafeEatL10n.format(
            L10nKey.History.weekRangeFormat,
            shortDate(start),
            shortDate(end)
        )
    }

    static func recordCount(_ count: Int) -> String {
        SafeEatL10n.format(
            count == 1 ? L10nKey.History.recordCountOne : L10nKey.History.recordCountOther,
            count
        )
    }

    static func dayCount(_ count: Int) -> String {
        SafeEatL10n.format(
            count == 1 ? L10nKey.History.dayCountOne : L10nKey.History.dayCountOther,
            count
        )
    }

    static func weekday(_ date: Date) -> String {
        switch Calendar.current.component(.weekday, from: date) {
        case 1:
            return SafeEatL10n.text(L10nKey.History.weekdaySunday)
        case 2:
            return SafeEatL10n.text(L10nKey.History.weekdayMonday)
        case 3:
            return SafeEatL10n.text(L10nKey.History.weekdayTuesday)
        case 4:
            return SafeEatL10n.text(L10nKey.History.weekdayWednesday)
        case 5:
            return SafeEatL10n.text(L10nKey.History.weekdayThursday)
        case 6:
            return SafeEatL10n.text(L10nKey.History.weekdayFriday)
        default:
            return SafeEatL10n.text(L10nKey.History.weekdaySaturday)
        }
    }
}

@MainActor
final class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            Task {
                if reminderEnabled {
                    await scheduleReminder()
                }
            }
        }
    }

    @Published var reminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reminderEnabled, forKey: Self.reminderKey)
        }
    }

    @Published var reminderStartDayOffset: Int {
        didSet {
            UserDefaults.standard.set(reminderStartDayOffset, forKey: Self.reminderStartDayKey)
        }
    }

    @Published var reminderTimeMinutes: Int {
        didSet {
            UserDefaults.standard.set(reminderTimeMinutes, forKey: Self.reminderTimeKey)
        }
    }

    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationMessage: String?

    private static let languageKey = "safeeat.settings.language"
    private static let reminderKey = "safeeat.settings.reminderEnabled"
    private static let reminderStartDayKey = "safeeat.settings.reminderStartDayOffset"
    private static let reminderTimeKey = "safeeat.settings.reminderTimeMinutes"
    private static let reminderIdentifierPrefix = "safeeat.daily.reminder"
    private static let reminderHorizonDays = 45

    private init() {
        if let rawValue = UserDefaults.standard.string(forKey: Self.languageKey),
           let storedLanguage = AppLanguage(rawValue: rawValue) {
            language = storedLanguage
        } else {
            language = AppLanguage.deviceDefault
        }

        reminderEnabled = UserDefaults.standard.bool(forKey: Self.reminderKey)
        reminderStartDayOffset = UserDefaults.standard.object(forKey: Self.reminderStartDayKey) as? Int ?? ReminderStartDay.today.rawValue
        reminderTimeMinutes = UserDefaults.standard.object(forKey: Self.reminderTimeKey) as? Int ?? (20 * 60 + 30)
    }

    var displayLocale: Locale {
        language.locale
    }

    var languageSummary: String {
        language.displayName
    }

    var reminderSummary: String {
        if reminderEnabled {
            return SafeEatL10n.format(
                L10nKey.Reminder.summaryFormat,
                reminderStartDayTitle,
                reminderTimeText
            )
        }

        switch notificationStatus {
        case .denied:
            return SafeEatL10n.text(L10nKey.Reminder.systemDenied)
        default:
            return SafeEatL10n.text(L10nKey.Reminder.off)
        }
    }

    var reminderTimeText: String {
        String(format: "%02d:%02d", reminderTimeMinutes / 60, reminderTimeMinutes % 60)
    }

    var reminderStartDayTitle: String {
        ReminderStartDay(rawValue: reminderStartDayOffset)?.title
            ?? SafeEatL10n.text(L10nKey.Reminder.optionToday)
    }

    func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus

        if settings.authorizationStatus != .authorized, settings.authorizationStatus != .provisional {
            reminderEnabled = false
            await removeReminder()
        } else if reminderEnabled {
            await scheduleReminder()
        }
    }

    @discardableResult
    func setReminderEnabled(_ enabled: Bool) async -> Bool {
        return await saveReminderSettings(
            enabled: enabled,
            startDayOffset: reminderStartDayOffset,
            timeMinutes: reminderTimeMinutes
        )
    }

    @discardableResult
    func saveReminderSettings(enabled: Bool, startDayOffset: Int, timeMinutes: Int) async -> Bool {
        reminderStartDayOffset = startDayOffset
        reminderTimeMinutes = timeMinutes

        if enabled {
            let granted = try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await refreshNotificationStatus()

            guard granted == true || notificationStatus == .authorized || notificationStatus == .provisional else {
                reminderEnabled = false
                notificationMessage = SafeEatL10n.text(L10nKey.Reminder.enableFailed)
                return false
            }

            reminderEnabled = true
            await scheduleReminder()
            notificationMessage = SafeEatL10n.text(L10nKey.Reminder.enabled)
            return true
        }

        reminderEnabled = false
        await removeReminder()
        notificationMessage = SafeEatL10n.text(L10nKey.Reminder.disabled)
        return true
    }

    private func scheduleReminder() async {
        let center = UNUserNotificationCenter.current()
        await removeReminder()

        guard reminderEnabled else { return }

        let calendar = Calendar.current
        let now = Date()
        let firstFireDate = firstReminderDate(from: now, calendar: calendar)

        for index in 0..<Self.reminderHorizonDays {
            guard let scheduledDate = calendar.date(byAdding: .day, value: index, to: firstFireDate) else { continue }

            let content = UNMutableNotificationContent()
            content.title = SafeEatL10n.text(L10nKey.Reminder.title)
            content.body = SafeEatL10n.text(L10nKey.Reminder.body)
            content.sound = .default

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.reminderIdentifier(for: index),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func removeReminder() async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: Self.reminderIdentifiers)
    }

    private func firstReminderDate(from now: Date, calendar: Calendar) -> Date {
        let dayOffset = max(0, min(reminderStartDayOffset, 1))
        let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        let hour = reminderTimeMinutes / 60
        let minute = reminderTimeMinutes % 60

        var firstFire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate) ?? baseDate
        if firstFire <= now {
            firstFire = calendar.date(byAdding: .day, value: 1, to: firstFire) ?? firstFire
        }

        return firstFire
    }

    private static func reminderIdentifier(for index: Int) -> String {
        "\(reminderIdentifierPrefix).\(index)"
    }

    private static var reminderIdentifiers: [String] {
        (0..<reminderHorizonDays).map(reminderIdentifier(for:))
    }

    static var reminderTimeOptions: [Int] {
        (6..<23).flatMap { hour in
            stride(from: 0, through: 45, by: 15).map { minute in
                hour * 60 + minute
            }
        }
    }
}
