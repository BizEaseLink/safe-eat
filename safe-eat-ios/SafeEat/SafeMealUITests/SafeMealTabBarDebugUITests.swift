import XCTest

final class SafeMealTabBarDebugUITests: XCTestCase {

    func testTabBarHiddenState() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLocale", "zh-Hans"]
        app.launch()

        // 进入菜单 tab
        let menuTab = app.buttons["菜单"]
        if menuTab.waitForExistence(timeout: 4) {
            menuTab.tap()
            sleep(1)
        }

        print("[UITEST] root after entering menu, floatingTabVisible=\(barVisible(app))")

        // 点 Day 入口
        let dayEntry = app.buttons["menuDayEntry"]
        if dayEntry.waitForExistence(timeout: 4) {
            dayEntry.tap()
            Thread.sleep(forTimeInterval: 1.5)
            print("[UITEST] in DayView, floatingTabVisible=\(barVisible(app))  (EXPECT false)")
        } else {
            print("[UITEST] menuDayEntry NOT FOUND")
        }

        // 返回
        back(app)
        Thread.sleep(forTimeInterval: 1.0)
        print("[UITEST] back at menu, floatingTabVisible=\(barVisible(app))  (EXPECT true)")

        // 点周入口
        let weekEntry = app.buttons["menuWeekEntry"]
        if weekEntry.waitForExistence(timeout: 4) {
            weekEntry.tap()
            Thread.sleep(forTimeInterval: 1.5)
            print("[UITEST] in WeekView, floatingTabVisible=\(barVisible(app))  (EXPECT false)")
        } else {
            print("[UITEST] menuWeekEntry NOT FOUND")
        }

        back(app)
        Thread.sleep(forTimeInterval: 1.0)
        print("[UITEST] back at menu, floatingTabVisible=\(barVisible(app))  (EXPECT true)")

        XCTAssertTrue(true, "diagnostic run - check stdout")
    }

    private func barVisible(_ app: XCUIApplication) -> Bool {
        let home = app.buttons["首页"].exists
        let profile = app.buttons["个人"].exists
        let menuBtn = app.buttons["菜单"].exists
        return home || profile || menuBtn
    }

    private func back(_ app: XCUIApplication) {
        // 顶部返回按钮（SafeEatTopBackChrome 自绘，可能是 button/biu 元素）
        let backBtns = app.buttons
        for candidate in ["返回", "Back", "chevron.backward"] {
            if backBtns[candidate].exists {
                backBtns[candidate].tap()
                return
            }
        }
        // 兜底：点击全屏左上角坐标
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.06)).tap()
    }
}