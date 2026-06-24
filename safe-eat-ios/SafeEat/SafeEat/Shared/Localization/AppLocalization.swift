import Foundation
import Combine
import UserNotifications

enum L10nKey {
    enum Brand {
        static let appName = "brand.app_name"
        static let slogan = "brand.slogan"
        static let sloganEn = "brand.slogan_en"
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
        static let retry = "common.retry"
    }

    enum Tab {
        static let home = "tab.home"
        static let menu = "tab.menu"
        static let trend = "tab.trend"
        static let profile = "tab.profile"
        static let scan = "tab.scan"
    }

    enum Advice {
        static let titleRecommended = "advice.title.recommended"
        static let titleModerate = "advice.title.moderate"
        static let titleCaution = "advice.title.caution"
        static let titleAvoid = "advice.title.avoid"
        static let titleEvaluate = "advice.title.evaluate"
        static let compactRecommended = "advice.compact.recommended"
        static let compactModerate = "advice.compact.moderate"
        static let compactCaution = "advice.compact.caution"
        static let compactAvoid = "advice.compact.avoid"
        static let compactEvaluate = "advice.compact.evaluate"
        static let summaryRecommended = "advice.summary.recommended"
        static let summaryModerate = "advice.summary.moderate"
        static let summaryCaution = "advice.summary.caution"
        static let summaryAvoid = "advice.summary.avoid"
        static let summaryEvaluate = "advice.summary.evaluate"
    }

    enum Reminder {
        static let on = "reminder.on"
        static let off = "reminder.off"
        static let systemDenied = "reminder.system_denied"
        static let enableFailed = "reminder.enable_failed"
        static let deniedTitle = "reminder.denied_title"
        static let deniedBody = "reminder.denied_body"
        static let deniedOpenSettings = "reminder.denied_open_settings"
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
        static let titleToday = "reminder.notification.title_today"
        static let bodyToday = "reminder.notification.body_today"
        static let titleYesterday = "reminder.notification.title_yesterday"
        static let bodyYesterday = "reminder.notification.body_yesterday"
        static let titleDate = "reminder.notification.title_date"
        static let bodyDate = "reminder.notification.body_date"
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
        static let networkUnavailable = "error.network_unavailable"
        static let localNetworkDeniedTitle = "error.local_network_denied_title"
        static let localNetworkDeniedBody = "error.local_network_denied_body"
        static let localNetworkOpenSettings = "error.local_network_open_settings"
        static let imageCaptureFailed = "error.image_capture_failed"
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
        static let loginPromptTitle = "auth.login_prompt.title"
        static let loginPromptMessage = "auth.login_prompt.message"
        static let loginPromptFeatureFormat = "auth.login_prompt.feature_format"
        static let loginPromptLater = "auth.login_prompt.later"
        static let orDivider = "auth.or_divider"
        static let newUserWelcomeTitle = "auth.new_user.welcome_title"
        static let newUserWelcomeMessage = "auth.new_user.welcome_message"
        static let newUserSetPassword = "auth.new_user.set_password"
        static let passwordLoginErrorTitle = "auth.password_login.error_title"
        static let passwordLoginErrorMessage = "auth.password_login.error_message"
        static let termsPrefix = "auth.terms.prefix"
        static let termsAnd = "auth.terms.and"
        static let termsUserAgreement = "auth.terms.user_agreement"
        static let termsPrivacyPolicy = "auth.terms.privacy_policy"
        static let resetPasswordTitle = "auth.reset_password.title"
        static let resetPasswordSubtitle = "auth.reset_password.subtitle"
        static let resetPasswordAction = "auth.reset_password.action"
        static let resetPasswordSuccess = "auth.reset_password.success"
        static let newPasswordLabel = "auth.field.new_password"
        static let forgotPassword = "auth.switch.forgot_password"
        static let smsSent = "auth.sms.sent"
        static let passwordRequirementLength = "auth.password.requirement.length"
        static let passwordRequirementUppercase = "auth.password.requirement.uppercase"
        static let passwordRequirementLowercase = "auth.password.requirement.lowercase"
        static let passwordRequirementDigit = "auth.password.requirement.digit"
        static let passwordRequirementSpecial = "auth.password.requirement.special"
    }

    enum Terms {
        static let purchasePrefix = "terms.purchase.prefix"
        static let purchaseValueAdded = "terms.purchase.value_added"
        static let purchaseAnd = "terms.purchase.and"
        static let purchaseAutoRenewal = "terms.purchase.auto_renewal"
        static let purchaseSuffix = "terms.purchase.suffix"
        static let deletePrefix = "terms.delete.prefix"
        static let deleteGuide = "terms.delete.guide"
        static let deleteSuffix = "terms.delete.suffix"
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
        static let notLoggedInAction = "profile.not_logged_in.action"
        static let healthProfileTitle = "profile.health_profile.title"
        static let healthProfileEdit = "profile.health_profile.edit"
        static let healthProfileEmpty = "profile.health_profile.empty"
        static let healthTagHighBloodSugar = "profile.health_profile.tag.high_blood_sugar"
        static let healthTagHighBloodPressure = "profile.health_profile.tag.high_blood_pressure"
        static let healthTagFatLoss = "profile.health_profile.tag.fat_loss"
        static let healthTagAvoid = "profile.health_profile.tag.avoid"
        static let healthProfileEmptyHint = "profile.health_profile.empty_hint"

        enum Member {
            static let freeTitle = "profile.member.free.title"
            static let freeSubtitle = "profile.member.free.subtitle"
            static let liteTitle = "profile.member.lite.title"
            static let liteSubtitle = "profile.member.lite.subtitle"
            static let proTitle = "profile.member.pro.title"
            static let proSubtitle = "profile.member.pro.subtitle"
            static let premiumTitle = "profile.member.premium.title"
            static let premiumSubtitle = "profile.member.premium.subtitle"
        }

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
            static let age = "profile.edit.age"
            static let agePlaceholder = "profile.edit.age_placeholder"
            static let activityLevel = "profile.edit.activity_level"
            static let activitySedentary = "profile.edit.activity.sedentary"
            static let activityLight = "profile.edit.activity.light"
            static let activityModerate = "profile.edit.activity.moderate"
            static let activityHeavy = "profile.edit.activity.heavy"
            static let activityAthlete = "profile.edit.activity.athlete"
            static let tdeeLabel = "profile.edit.tdee_label"
            static let tdeeUnit = "profile.edit.tdee_unit"
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
            static let changePhone = "profile.security.change_phone"
            static let changePassword = "profile.security.change_password"
            static let deleteAccount = "profile.security.delete_account"
            static let restorePurchases = "profile.security.restore_purchases"
        }

        enum ChangePhone {
            static let title = "profile.change_phone.title"
            static let subtitle = "profile.change_phone.subtitle"
            static let stepVerifyCurrent = "profile.change_phone.step_verify_current"
            static let stepInputNew = "profile.change_phone.step_input_new"
            static let currentPhoneLabel = "profile.change_phone.current_phone_label"
            static let newPhoneLabel = "profile.change_phone.new_phone_label"
            static let verifyCurrentCode = "profile.change_phone.verify_current_code"
            static let sendNewCode = "profile.change_phone.send_new_code"
            static let success = "profile.change_phone.success"
        }

        enum ChangePassword {
            static let title = "profile.change_password.title"
            static let subtitle = "profile.change_password.subtitle"
            static let oldPassword = "profile.change_password.old_password"
            static let newPassword = "profile.change_password.new_password"
            static let confirmPassword = "profile.change_password.confirm_password"
            static let oldPasswordPlaceholder = "profile.change_password.old_password_placeholder"
            static let newPasswordPlaceholder = "profile.change_password.new_password_placeholder"
            static let confirmPasswordPlaceholder = "profile.change_password.confirm_password_placeholder"
            static let mismatchError = "profile.change_password.mismatch_error"
            static let success = "profile.change_password.success"
        }

        enum DeleteAccount {
            static let title = "profile.delete_account.title"
            static let subtitle = "profile.delete_account.subtitle"
            static let warningTitle = "profile.delete_account.warning_title"
            static let warningBody = "profile.delete_account.warning_body"
            static let confirmButton = "profile.delete_account.confirm_button"
            static let confirmDialogTitle = "profile.delete_account.confirm_dialog_title"
            static let confirmDialogMessage = "profile.delete_account.confirm_dialog_message"
            static let success = "profile.delete_account.success"
        }

        enum RestorePurchases {
            static let title = "profile.restore_purchases.title"
            static let subtitle = "profile.restore_purchases.subtitle"
            static let restoring = "profile.restore_purchases.restoring"
            static let success = "profile.restore_purchases.success"
            static let empty = "profile.restore_purchases.empty"
            static let failed = "profile.restore_purchases.failed"
        }

        enum Feedback {
            static let title = "profile.feedback.title"
            static let subtitle = "profile.feedback.subtitle"
            static let deviceLabel = "profile.feedback.device_label"
            static let versionLabel = "profile.feedback.version_label"
            static let version = "profile.feedback.version"
            static let device = "profile.feedback.device"
            static let hint = "profile.feedback.hint"
            static let emailAction = "profile.feedback.email_action"
        }

        enum Update {
            static let title = "profile.update.title"
            static let subtitle = "profile.update.subtitle"
            static let versionLabel = "profile.update.version_label"
            static let version = "profile.update.version"
            static let latest = "profile.update.latest"
            static let checkAction = "profile.update.check_action"
        }

        enum About {
            static let title = "profile.about.page_title"
            static let subtitle = "profile.about.page_subtitle"
            static let appName = "profile.about.app_name"
            static let intro = "profile.about.intro"
            static let sectionTitle = "profile.about.section_title"
            static let sectionBody = "profile.about.section_body"
            static let disclosureSection = "profile.about.disclosure_section"
            static let userAgreement = "profile.about.user_agreement"
            static let privacyPolicy = "profile.about.privacy_policy"
            static let valueAdded = "profile.about.value_added"
            static let minorProtection = "profile.about.minor_protection"
            static let autoRenewalNotice = "profile.about.auto_renewal_notice"
            static let permissionUsage = "profile.about.permission_usage"
            static let aiDisclaimer = "profile.about.ai_disclaimer"
            static let adServiceNotice = "profile.about.ad_service_notice"
            static let cancellationGuide = "profile.about.cancellation_guide"
            static let certificate = "profile.about.certificate"
            static let copyright = "profile.about.copyright"
        }

        enum Redeem {
            static let title = "profile.redeem.title"
            static let subtitle = "profile.redeem.subtitle"
            static let action = "profile.redeem.action"
            static let inputLabel = "profile.redeem.input_label"
            static let inputHint = "profile.redeem.input_hint"
            static let inputPlaceholder = "profile.redeem.input_placeholder"
            static let failedMessage = "profile.redeem.failed"
        }

        enum Help {
            static let title = "profile.help.title"
            static let subtitle = "profile.help.subtitle"
            static let contactSection = "profile.help.contact_section"
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
        static let newMemberOffer = "membership.purchase.new_member_offer"
        static let badgePremium = "membership.purchase.badge.premium"
        static let subtitlePremium = "membership.purchase.plan_subtitle.premium"
        static let restorePurchases = "membership.purchase.restore_purchases"
        static let purchasing = "membership.purchase.purchasing"
        static let subscribeWithPrice = "membership.purchase.subscribe_with_price"
        static let purchaseSuccess = "membership.purchase.purchase_success"
        static let purchasePending = "membership.purchase.purchase_pending"
        static let restoreEmpty = "membership.purchase.restore_empty"
        static let productNotReady = "membership.purchase.product_not_ready"
        static let verifyFailed = "membership.purchase.verify_failed"
        static let verifyError = "membership.purchase.verify_error"
        static let freePlanDescription = "membership.purchase.free_plan_description"
        static let countdownLabel = "membership.purchase.countdown_label"
        static let countdownFormat = "membership.purchase.countdown_format"
        static let originalPrice = "membership.purchase.original_price"
        static let priceBreakdownTitle = "membership.purchase.price_breakdown_title"
        static let priceBreakdownOriginal = "membership.purchase.price_breakdown_original"
        static let priceBreakdownAppleOffer = "membership.purchase.price_breakdown_apple_offer"
        static let priceBreakdownCampaign = "membership.purchase.price_breakdown_campaign"
        static let priceBreakdownBonus = "membership.purchase.price_breakdown_bonus"
        static let priceBreakdownPayment = "membership.purchase.price_breakdown_payment"
        static let campaignBonusDays = "membership.purchase.campaign_bonus_days"
        static let campaignBonusQuota = "membership.purchase.campaign_bonus_quota"
        static let campaignBonusAiQuota = "membership.purchase.campaign_bonus_ai_quota"
        static let redeemCodeTitle = "membership.purchase.redeem_code_title"
        static let redeemCodePlaceholder = "membership.purchase.redeem_code_placeholder"
        static let redeemCodeConfirm = "membership.purchase.redeem_code_confirm"
        static let redeemCodeSuccess = "membership.purchase.redeem_code_success"
        static let redeemCodeInvalid = "membership.purchase.redeem_code_invalid"
        static let buyNowWithBonus = "membership.purchase.buy_now_with_bonus"
        static let membershipStatusExpired = "membership.purchase.status_expired"
        static let membershipStatusCanceled = "membership.purchase.status_canceled"
        static let membershipStatusGracePeriod = "membership.purchase.status_grace_period"
        static let membershipStatusTrialing = "membership.purchase.status_trialing"
        static let trialPromptTitle = "membership.purchase.trial_prompt_title"
        static let trialPromptBody = "membership.purchase.trial_prompt_body"
        static let trialPromptAction = "membership.purchase.trial_prompt_action"
        static let yearlyPriceHint = "membership.purchase.yearly_price_hint"
        static let trialPromptBodyWithDays = "membership.purchase.trial_prompt_body_with_days"
        static let freeTrialBadge = "membership.purchase.free_trial_badge"
        static let freeTrialDays = "membership.purchase.free_trial_days"
        static let trialActive = "membership.purchase.trial_active"
        static let trialEndsOn = "membership.purchase.trial_ends_on"
        static let trialDisclaimer = "membership.purchase.trial_disclaimer"
        static let firstPurchaseBonusTitle = "membership.purchase.first_purchase_bonus_title"
        static let firstPurchaseBonusSubtitle = "membership.purchase.first_purchase_bonus_subtitle"
        static let firstPurchaseBonusDays = "membership.purchase.first_purchase_bonus_days"
        static let firstPurchaseBonusRecognition = "membership.purchase.first_purchase_bonus_recognition"
        static let firstPurchaseBonusAi = "membership.purchase.first_purchase_bonus_ai"
        static let firstPurchaseClaimButton = "membership.purchase.first_purchase_claim_button"
        static let firstPurchaseClaimed = "membership.purchase.first_purchase_claimed"
        static let planBonusBadge = "membership.purchase.plan_bonus_badge"
        static let planBonusDays = "membership.purchase.plan_bonus_days"
        static let planBonusRecognition = "membership.purchase.plan_bonus_recognition"
        static let planBonusAi = "membership.purchase.plan_bonus_ai"
        static let newUserGiftBanner = "membership.purchase.new_user_gift_banner"
        static let badgeLite = "membership.purchase.badge.lite"
        static let currentPlanBadge = "membership.purchase.badge.current"
        static let benefitRecognitionMonthly = "membership.purchase.benefit.recognition_monthly"
        static let benefitAiMonthly = "membership.purchase.benefit.ai_monthly"
        static let benefitDailyQuota = "membership.purchase.benefit.daily_quota"
        static let benefitAiAdviceLevel = "membership.purchase.benefit.ai_advice_level"
        static let benefitMaxHealthProfiles = "membership.purchase.benefit.max_health_profiles"
        static let benefitHistoryLimit = "membership.purchase.benefit.history_limit"
        static let benefitHistoryLimitUnlimited = "membership.purchase.benefit.history_limit_unlimited"
        static let redeemCodeEntryTitle = "membership.purchase.redeem_code_entry_title"
        static let redeemCodeEntrySubtitle = "membership.purchase.redeem_code_entry_subtitle"
        static let redeemCodeSheetTitle = "membership.purchase.redeem_code_sheet_title"
        static let redeemCodeAction = "membership.purchase.redeem_code_action"
        static let priceBreakdownAppleFinal = "membership.purchase.price_breakdown_apple_final"
        static let plansLoadError = "membership.purchase.plans_load_error"
        static let noPlansAvailable = "membership.purchase.no_plans_available"
        static let confirmOriginalPrice = "membership.purchase.confirm_original_price"
        static let confirmBonusTitle = "membership.purchase.confirm_bonus_title"
        static let confirmAppleOffer = "membership.purchase.confirm_apple_offer"
        static let confirmFinalPriceHint = "membership.purchase.confirm_final_price_hint"
        static let confirmPayButton = "membership.purchase.confirm_pay_button"
        static let confirmSheetTitle = "membership.purchase.confirm_sheet_title"
        static let detailRecognitionMonthlyLabel = "membership.purchase.detail.recognition_monthly_label"
        static let detailCountFormat = "membership.purchase.detail.count_format"
        static let detailAiAdviceLevelLabel = "membership.purchase.detail.ai_advice_level_label"
        static let detailHealthProfilesLabel = "membership.purchase.detail.health_profiles_label"
        static let detailHealthProfilesFormat = "membership.purchase.detail.health_profiles_format"
        static let detailHistoryLabel = "membership.purchase.detail.history_label"
        static let detailHistoryUnlimited = "membership.purchase.detail.history_unlimited"
        static let detailHistoryCountFormat = "membership.purchase.detail.history_count_format"
        static let detailBenefitsTitle = "membership.purchase.detail.benefits_title"
        static let detailNavTitle = "membership.purchase.detail.nav_title"
        static let selectPlan = "membership.purchase.select_plan"
        static let bonusDaysFormat = "membership.purchase.bonus.days_format"
        static let bonusRecognitionFormat = "membership.purchase.bonus.recognition_format"
        static let bonusAiFormat = "membership.purchase.bonus.ai_format"
        static let bonusSeparator = "membership.purchase.bonus.separator"
    }

    enum Home {
        static let title = "home.title"
        static let brandPill = "home.brand_pill"
        static let promoTag = "home.promo.tag"
        static let promoValue = "home.promo.value"
        static let heroTagHealth = "home.hero.tag.health"
        static let heroTagHistory = "home.hero.tag.history"
        static let heroTagKnow = "home.hero.tag.know"
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
        static let cameraTitle = "home.camera.title"
        static let cameraBottomHint = "home.camera.bottom_hint"
        static let cameraFlashOn = "home.camera.flash_on"
        static let cameraFlashOff = "home.camera.flash_off"
        static let cameraStarting = "home.camera.starting"
        static let cameraPermissionOff = "home.camera.permission_off"
        static let cameraUnsupported = "home.camera.unsupported"
        static let cameraStartFailed = "home.camera.start_failed"
        static let cameraCaptureFailed = "home.camera.capture_failed"
        static let imageProcessFailed = "home.error.image_process_failed"
        static let quotaExceededTitle = "home.quota_exceeded.title"
        static let quotaExceededMessage = "home.quota_exceeded.message"
        static let quotaExceededSubtitle = "home.quota_exceeded.subtitle"
        static let quotaExceededStatusFormat = "home.quota_exceeded.status_format"
        static let quotaExceededProgressLabel = "home.quota_exceeded.progress_label"
        static let quotaExceededMemberHint = "home.quota_exceeded.member_hint"
        static let quotaExceededUpgrade = "home.quota_exceeded.upgrade"
        static let quotaExceededWatchAd = "home.quota_exceeded.watch_ad"
        static let quotaExceededWatchAdRecoverFormat = "home.quota_exceeded.watch_ad_recover_format"
        static let quotaExceededWatchAdWithCount = "home.quota_exceeded.watch_ad_with_count"
        static let quotaExceededAdRewardFormat = "home.quota_exceeded.ad_reward_format"
        static let quotaExceededTomorrow = "home.quota_exceeded.tomorrow"
        static let quotaExceededTotalTitle = "home.quota_exceeded.total_title"
        static let quotaExceededTotalFootnoteFormat = "home.quota_exceeded.total_footnote_format"
        static let quotaExceededFreeQuotaTitle = "home.quota_exceeded.free_quota_title"
        static let quotaExceededAdQuotaTitle = "home.quota_exceeded.ad_quota_title"
        static let quotaExceededAdRemainingFormat = "home.quota_exceeded.ad_remaining_format"
        static let quotaExceededRuleFormat = "home.quota_exceeded.rule_format"
        static let adRewardClaimFailed = "home.ad_reward.claim_failed"
        static let adLoadFailed = "home.ad_reward.load_failed"
        static let adRewardSuccess = "home.ad_reward.success"
        static let adRewardSuccessTitle = "home.ad_reward.success_title"
        static let adRewardClaimFailedTitle = "home.ad_reward.claim_failed_title"
        static let adLoadFailedTitle = "home.ad_reward.load_failed_title"
        static let adRewardRetry = "home.ad_reward.retry"
        static let adRewardSuccessQuotaFormat = "home.ad_reward.success_quota_format"
        static let quotaRemainingFormat = "home.quota_remaining.format"
        static let quotaMonthlyRemainingFormat = "home.quota_monthly_remaining.format"
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
        static let chipModerate = "home.record.chip_moderate"
        static let chipPortion = "home.record.chip_portion"
        static let chipSwitch = "home.record.chip_switch"
        static let chipCheck = "home.record.chip_check"
        static let summaryRecommended = "home.record.summary.recommended"
        static let summaryModerate = "home.record.summary.moderate"
        static let summaryCaution = "home.record.summary.caution"
        static let summaryAvoid = "home.record.summary.avoid"
        static let summaryUnknown = "home.record.summary.unknown"
        static let unknownFood = "home.record.unknown_food"
        static let signupBonusWelcomeTitle = "home.signup_bonus.welcome_title"
        static let signupBonusQuotaFormat = "home.signup_bonus.quota_format"
        static let signupBonusSubtitle = "home.signup_bonus.subtitle"
        static let signupBonusStartAction = "home.signup_bonus.start_action"
        static let quotaExceededDailyTitle = "home.quota_exceeded.daily_title"
        static let quotaExceededMonthlyTitle = "home.quota_exceeded.monthly_title"
        static let quotaExceededDailyHintFormat = "home.quota_exceeded.daily_hint_format"
        static let quotaExceededMonthlyHintFormat = "home.quota_exceeded.monthly_hint_format"
        static let quotaExceededUpgradeHint = "home.quota_exceeded.upgrade_hint"
        static let quotaExceededWatchAdAction = "home.quota_exceeded.watch_ad_action"
        static let quotaExceededUpgradeMembership = "home.quota_exceeded.upgrade_membership"
        static let quotaExceededUpgradePlan = "home.quota_exceeded.upgrade_plan"
        static let quotaExceededLater = "home.quota_exceeded.later"
        static let quotaExceededWatchAdHint = "home.quota_exceeded.watch_ad_hint"
        static let quotaStatusBarDailyLabel = "home.quota_status_bar.daily_label"
        static let quotaStatusBarMonthlyLabel = "home.quota_status_bar.monthly_label"
        static let quotaStatusBarCountFormat = "home.quota_status_bar.count_format"
        static let quotaStatusBarAdRewardFormat = "home.quota_status_bar.ad_reward_format"
        static let quotaStatusBarCycleEndFormat = "home.quota_status_bar.cycle_end_format"
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
        static let mealLateNight = "menu.meal.late_night"
        static let notLoggedInTitle = "menu.not_logged_in.title"
        static let notLoggedInMessage = "menu.not_logged_in.message"
        static let dailyHealthOverview = "menu.daily.health_overview"
        static let dailyAvgScore = "menu.daily.avg_score"
        static let dailyTotalCalories = "menu.daily.total_calories"
        static let dailyScanCountFormat = "menu.daily.scan_count_format"
        static let dailyScanCount = "menu.daily.scan_count"
        static let dailyScanLog = "menu.daily.scan_log"
        static let weeklyTrendGood = "menu.weekly.trend_good"
        static let weeklyTrendModerate = "menu.weekly.trend_moderate"
        static let weeklyTrendPoor = "menu.weekly.trend_poor"
        static let weeklyConsecutiveDaysFormat = "menu.weekly.consecutive_days_format"
        static let weeklyScanCount = "menu.weekly.scan_count"
        static let weeklyAvgScore = "menu.weekly.avg_score"
        static let weeklyViewDetail = "menu.weekly.view_detail"
        static let weeklyUsageStats = "menu.weekly.usage_stats"
        static let weeklyScanCountFormat = "menu.weekly.scan_count_format"
        static let mealSectionTitle = "menu.meal.section_title"
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
        static let actionBackToFront = "result.action.back_to_front"
        static let detailSyncing = "result.detail.syncing"
        static let detailLocalOnly = "result.detail.local_only"
        static let nutritionSectionTitle = "result.section.nutrition"
        static let adviceSectionTitle = "result.section.advice"
        static let riskSectionTitle = "result.section.risk"
        static let imageMissing = "result.image_missing"
        static let missingTitle = "result.missing.title"
        static let missingMessage = "result.missing.message"
        static let missingRetry = "result.missing.retry"
        static let reasonSeparator = "result.reason.separator"
        // Phase 8C: 评分圆环 + 推荐等级 + 营养指标 + 风险标签 + AI 建议
        static let scoreLabel = "result.score.label"
        static let recommendHighly = "result.recommendation.highly"
        static let recommendYes = "result.recommendation.yes"
        static let recommendModerate = "result.recommendation.moderate"
        static let recommendCautious = "result.recommendation.cautious"
        static let recommendNo = "result.recommendation.no"
        static let metricTitle = "result.metric_impacts.title"
        static let metricScoreFormat = "result.metric_impacts.score_format"
        static let riskTitle = "result.risk_facts.title"
        static let aiAdviceTitle = "result.ai_advice.title"
        static let aiAdviceSummaryLabel = "result.ai_advice.summary_label"
        static let aiAdviceDetailedLabel = "result.ai_advice.detailed_label"
        static let healthTipsTitle = "result.ai_advice.health_tips_title"
        static let upgradeForMoreAdvice = "result.ai_advice.upgrade_hint"
        static let upgradeTierHintFormat = "result.ai_advice.upgrade_tier_hint_format"
        // C1: 快捷指标卡
        static let quickMetricGlycemicIndex = "result.quick_metric.glycemic_index"
        // C3: 维生素名称
        static let vitA = "result.vit.a"
        static let vitC = "result.vit.c"
        static let vitD = "result.vit.d"
        static let vitE = "result.vit.e"
        static let vitK = "result.vit.k"
        static let vitB1 = "result.vit.b1"
        static let vitB2 = "result.vit.b2"
        static let vitB3 = "result.vit.b3"
        static let vitB5 = "result.vit.b5"
        static let vitB6 = "result.vit.b6"
        static let vitB9 = "result.vit.b9"
        static let vitB12 = "result.vit.b12"
        static let vitBiotin = "result.vit.biotin"
        static let vitCholine = "result.vit.choline"
        static let vitFolate = "result.vit.folate"
        // C3: 矿物质名称
        static let mineralCalcium = "result.mineral.calcium"
        static let mineralIron = "result.mineral.iron"
        static let mineralMagnesium = "result.mineral.magnesium"
        static let mineralPhosphorus = "result.mineral.phosphorus"
        static let mineralPotassium = "result.mineral.potassium"
        static let mineralZinc = "result.mineral.zinc"
        static let mineralCopper = "result.mineral.copper"
        static let mineralManganese = "result.mineral.manganese"
        static let mineralSelenium = "result.mineral.selenium"
        static let mineralChromium = "result.mineral.chromium"
        static let mineralMolybdenum = "result.mineral.molybdenum"
        static let mineralFluoride = "result.mineral.fluoride"
        static let mineralIodine = "result.mineral.iodine"
        static let quickMetricGlycemicLow = "result.quick_metric.glycemic.low"
        static let quickMetricGlycemicMedium = "result.quick_metric.glycemic.medium"
        static let quickMetricGlycemicHigh = "result.quick_metric.glycemic.high"
        static let quickMetricCaloriesUnit = "result.quick_metric.calories_unit"
        static let quickMetricProteinUnit = "result.quick_metric.protein_unit"
        static let quickMetricFatUnit = "result.quick_metric.fat_unit"
        // MOB-2: 历史记录详情
        static let recognitionInfoLabel = "result.recognition_info_label"
        static let metricImpactsLabel = "result.metric_impacts_label"
        static let riskFactsLabel = "result.risk_facts_label"
        static let aiAdviceHealthTipsLabel = "result.ai_advice.health_tips_label"
        // T6: 过敏原标签 + 饱腹感指数
        static let allergenTitle = "result.allergen.title"
        static let allergenContains = "result.allergen.contains"
        static let allergenMayContain = "result.allergen.may_contain"
        static let satietyTitle = "result.satiety.title"
        static let satietyLow = "result.satiety.low"
        static let satietyMedium = "result.satiety.medium"
        static let satietyHigh = "result.satiety.high"
        // T7: 背面长滚动 10 Section
        static let sectionMacronutrients = "result.section.macronutrients"
        static let sectionDetailedNutrients = "result.section.detailed_nutrients"
        static let sectionVitamins = "result.section.vitamins"
        static let sectionMinerals = "result.section.minerals"
        static let sectionOtherTraceMinerals = "result.section.other_trace_minerals"
        static let sectionDailyValues = "result.section.daily_values"
        static let sectionGlycemic = "result.section.glycemic"
        static let sectionDietary = "result.section.dietary"
        static let sectionIngredients = "result.section.ingredients"
        static let glycemicIndex = "result.glycemic.index"
        static let glycemicLoad = "result.glycemic.load"
        static let insulinIndex = "result.glycemic.insulin_index"
        static let sugarContent = "result.glycemic.sugar"
        static let dietVegetarian = "result.diet.vegetarian"
        static let dietVegan = "result.diet.vegan"
        static let dietGlutenFree = "result.diet.gluten_free"
        static let dietLactoseFree = "result.diet.lactose_free"
        static let dietHalal = "result.diet.halal"
        static let dietLowFodmap = "result.diet.low_fodmap"
        static let dietDairyFree = "result.diet.dairy_free"
        static let dietNutFree = "result.diet.nut_free"
        static let preparation = "result.preparation"
        static let per100gServing = "result.per_100g_serving"
        // T7: 详细营养素本地化
        static let saturatedFat = "result.nutrient.saturated_fat"
        static let transFat = "result.nutrient.trans_fat"
        static let dietaryFiber = "result.nutrient.dietary_fiber"
        static let sugarNutrient = "result.nutrient.sugar"
        static let cholesterol = "result.nutrient.cholesterol"
        static let sodium = "result.nutrient.sodium"
        // T7: 制备方式本地化
        static let prepMethod = "result.prep.method"
        static let prepOilType = "result.prep.oil_type"
        static let prepOilAmount = "result.prep.oil_amount"
        static let prepSaltLevel = "result.prep.salt_level"
        static let prepSugarLevel = "result.prep.sugar_level"
        // T8: 付费墙遮罩
        static let paywallUpgradeHint = "result.paywall.upgrade_hint"
        static let paywallUpgradeAction = "result.paywall.upgrade_action"
        // C2: 背面头部扫描时间
        static let scannedNow = "result.scanned_now"
        static let scannedRelativeFormat = "result.scanned_relative_format"
        static let glycemicNotCollected = "result.glycemic.not_collected"
        static let dataNotAvailable = "result.data.not_available"
        static let feedbackPending = "result.feedback_pending"
        // 会员引导横幅
        static let membershipBannerTitleFree = "result.membership_banner.title_free"
        static let membershipBannerTitleLite = "result.membership_banner.title_lite"
        static let membershipBannerTitlePro = "result.membership_banner.title_pro"
        static let membershipBannerSubtitleFree = "result.membership_banner.subtitle_free"
        static let membershipBannerSubtitleLite = "result.membership_banner.subtitle_lite"
        static let membershipBannerSubtitlePro = "result.membership_banner.subtitle_pro"
        static let membershipBannerDescFree = "result.membership_banner.desc_free"
        static let membershipBannerDescLite = "result.membership_banner.desc_lite"
        static let membershipBannerDescPro = "result.membership_banner.desc_pro"
        static let membershipBannerAction = "result.membership_banner.action"
        // 其他微量元素 — 使用 sectionOtherTraceMinerals
        static let perServing = "result.nutrition.per_serving"
        static let actionAnalysisDetail = "result.action.analysis_detail"
        static let emptyDataHint = "result.empty_data_hint"
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
        static let typeTitle = "feedback.type.title"
        static let typePlaceholder = "feedback.type.placeholder"
        static let typeHint = "feedback.type.hint"
        static let typeWrongFood = "feedback.type.wrong_food"
        static let typeWrongName = "feedback.type.wrong_name"
        static let typeWrongNutrition = "feedback.type.wrong_nutrition"
        static let typeWrongCategory = "feedback.type.wrong_category"
        static let typeAddAlias = "feedback.type.add_alias"
        static let typeNewFood = "feedback.type.new_food"
        static let typeOther = "feedback.type.other"
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
        // MOB-2: 服务器历史记录
        static let serverNavTitle = "history.server.nav_title"
        static let serverEmptyTitle = "history.server.empty_title"
        static let serverEmptyMessage = "history.server.empty_message"
        static let serverRecordCountFormat = "history.server.record_count_format"
        static let upgradePromptTitle = "history.server.upgrade_prompt_title"
        static let upgradePromptMessageFormat = "history.server.upgrade_prompt_message_format"
        static let upgradePromptAction = "history.server.upgrade_prompt_action"
        static let loadingTitle = "history.server.loading_title"
        static let dateLabel = "history.date_label"
    }

    enum Sticker {
        static let swipeHint = "sticker.swipe_hint"
        static let resultTitle = "sticker.result_title"
    }

    enum Order {
        static let title = "order.history.title"
        static let subtitle = "order.history.subtitle"
        static let emptyTitle = "order.history.empty_title"
        static let emptyMessage = "order.history.empty_message"
        static let statusPending = "order.status.pending"
        static let statusPaid = "order.status.paid"
        static let statusFailed = "order.status.failed"
        static let statusCancelled = "order.status.cancelled"
        static let orderNoLabel = "order.detail.order_no"
        static let planLabel = "order.detail.plan"
        static let amountLabel = "order.detail.amount"
        static let statusLabel = "order.detail.status"
        static let channelLabel = "order.detail.channel"
        static let createdAtLabel = "order.detail.created_at"
        static let paidAtLabel = "order.detail.paid_at"
    }

    enum User {
        static let unnamed = "user.unnamed"
        static let tierFreeTitle = "user.tier.free.title"
        static let tierLiteTitle = "user.tier.lite.title"
        static let tierProTitle = "user.tier.pro.title"
        static let tierPremiumTitle = "user.tier.premium.title"
        static let tierFreeShort = "user.tier.free.short"
        static let tierLiteShort = "user.tier.lite.short"
        static let tierProShort = "user.tier.pro.short"
        static let tierPremiumShort = "user.tier.premium.short"
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
        static let paymentAppleIAP = "user.payment.apple_iap"
    }

    enum HealthGoal {
        static let navTitle = "health_goal.nav_title"
        static let groupHealthRisk = "health_goal.group.health_risk"
        static let groupLifeGoal = "health_goal.group.life_goal"
        static let limitHintFormat = "health_goal.limit_hint_format"
        static let primaryTag = "health_goal.primary_tag"
        static let setPrimaryAction = "health_goal.action.set_primary"
        static let unsetPrimaryAction = "health_goal.action.unset_primary"
        static let removeAction = "health_goal.action.remove"
        static let saveAction = "health_goal.action.save"
        static let cancelAction = "health_goal.action.cancel"
        static let templateHypertension = "health_goal.template.hypertension"
        static let templateHyperglycemia = "health_goal.template.hyperglycemia"
        static let templateHyperlipidemia = "health_goal.template.hyperlipidemia"
        static let templateGout = "health_goal.template.gout"
        static let templateKidney = "health_goal.template.kidney"
        static let templateWeightLoss = "health_goal.template.weight_loss"
        static let templateMuscleGain = "health_goal.template.muscle_gain"
        static let templateBalanced = "health_goal.template.balanced"
        static let templateCardiovascular = "health_goal.template.cardiovascular"
        static let templateBloodSugarControl = "health_goal.template.blood_sugar_control"
        static let templateGeneralWellness = "health_goal.template.general_wellness"
    }

    enum RecognitionPhase {
        static let identifying = "recognition_phase.identifying"
        static let selectTitle = "recognition_phase.select_title"
        static let selectSubtitle = "recognition_phase.select_subtitle"
        static let evaluating = "recognition_phase.evaluating"
        static let evaluatingSubtitle = "recognition_phase.evaluating_subtitle"
        static let tagIdentify = "recognition_phase.tag_identify"
        static let tagIdentifyDetail = "recognition_phase.tag_identify_detail"
        static let tagNutrition = "recognition_phase.tag_nutrition"
        static let tagNutritionDetail = "recognition_phase.tag_nutrition_detail"
        static let tagSafety = "recognition_phase.tag_safety"
        static let tagSafetyDetail = "recognition_phase.tag_safety_detail"
        static let tip = "recognition_phase.tip"
        static let tipContent1 = "recognition_phase.tip_content_1"
        static let tipContent2 = "recognition_phase.tip_content_2"
        static let tipContent3 = "recognition_phase.tip_content_3"
        static let tipContent4 = "recognition_phase.tip_content_4"
        static let nonFoodTitle = "recognition_phase.non_food_title"
        static let nonFoodSubtitle = "recognition_phase.non_food_subtitle"
    }

    enum Candidate {
        static let title = "candidate.title"
        static let aiResult = "candidate.ai_result"
        static let searchHint = "candidate.search_hint"
        static let searchPlaceholder = "candidate.search_placeholder"
        static let noResult = "candidate.no_result"
        static let emptyHint = "candidate.empty_hint"
    }

    enum Message {
        static let centerTitle = "message.center.title"
        static let emptyTitle = "message.empty.title"
        static let emptySubtitle = "message.empty.subtitle"
        static let markAllRead = "message.mark_all_read"
        static let typeMarketing = "message.type.marketing"
        static let typeAppUpdate = "message.type.app_update"
        static let typeDisclosureUpdate = "message.type.disclosure_update"
        static let typeFoodSafetyAlert = "message.type.food_safety_alert"
        static let typeFeedbackResolved = "message.type.feedback_resolved"
        static let typeFeedbackReward = "message.type.feedback_reward"
        static let typeAnnualReport = "message.type.annual_report"
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
    private static let languageKey = "safeeat.settings.language"

    static var isZh: Bool { currentLanguage == .zhHans }

    static func text(_ key: String) -> String {
        bundle(for: currentLanguage)
            .localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: currentLanguage.locale, arguments: arguments)
    }

    nonisolated private static var currentLanguage: AppLanguage {
        if let rawValue = UserDefaults.standard.string(forKey: languageKey),
           let stored = AppLanguage(rawValue: rawValue) {
            return stored
        }
        return AppLanguage.deviceDefault
    }

    nonisolated private static func bundle(for language: AppLanguage) -> Bundle {
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
    private static var currentDisplayLocale: Locale {
        currentLanguage.locale
    }

    private static let languageKey = "safeeat.settings.language"

    private static var currentLanguage: AppLanguage {
        if let rawValue = UserDefaults.standard.string(forKey: languageKey),
           let stored = AppLanguage(rawValue: rawValue) {
            return stored
        }
        return AppLanguage.deviceDefault
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentDisplayLocale
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
    @Published var showNotificationDenied = false

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
            // 先刷新权限状态
            await refreshNotificationStatus()

            // 已被用户拒绝，无法再弹系统弹窗，引导去设置
            if notificationStatus == .denied {
                reminderEnabled = false
                showNotificationDenied = true
                return false
            }

            // 首次请求或未决定状态，弹出系统授权弹窗
            if notificationStatus == .notDetermined {
                let granted = try? await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                await refreshNotificationStatus()

                guard granted == true || notificationStatus == .authorized || notificationStatus == .provisional else {
                    reminderEnabled = false
                    notificationMessage = SafeEatL10n.text(L10nKey.Reminder.enableFailed)
                    return false
                }
            }

            // 已授权或临时授权
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

            // 通知指向的目标日期：scheduledDate 当天的饮食记录
            let targetDate = calendar.startOfDay(for: scheduledDate)

            // 根据目标日期与今天的关系动态生成文案
            let (title, body) = notificationContent(for: targetDate, calendar: calendar)

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            // 存入目标日期供点击跳转使用
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate]
            content.userInfo = ["targetDate": isoFormatter.string(from: targetDate)]

            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            dateComponents.timeZone = calendar.timeZone
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.reminderIdentifier(for: index),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// 根据目标日期与今天的关系生成通知文案
    private func notificationContent(for targetDate: Date, calendar: Calendar) -> (title: String, body: String) {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: targetDate)

        if calendar.isDate(target, inSameDayAs: today) {
            return (
                SafeEatL10n.text(L10nKey.Reminder.titleToday),
                SafeEatL10n.text(L10nKey.Reminder.bodyToday)
            )
        }

        // 目标日期是昨天（选择"明天"时，通知在明天触发，指向昨天的总结）
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), calendar.isDate(target, inSameDayAs: yesterday) {
            return (
                SafeEatL10n.text(L10nKey.Reminder.titleYesterday),
                SafeEatL10n.text(L10nKey.Reminder.bodyYesterday)
            )
        }

        // 其他日期：包含日期
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = AppSettingsStore.shared.language == .en ? "MMM d" : "M月d日"
        let dateStr = formatter.string(from: target)
        return (
            SafeEatL10n.format(L10nKey.Reminder.titleDate, dateStr),
            SafeEatL10n.format(L10nKey.Reminder.bodyDate, dateStr)
        )
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

        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        comps.timeZone = calendar.timeZone

        guard var firstFire = calendar.date(from: comps) else { return baseDate }
        if firstFire <= now {
            comps.day = (comps.day ?? 0) + 1
            firstFire = calendar.date(from: comps) ?? firstFire
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
