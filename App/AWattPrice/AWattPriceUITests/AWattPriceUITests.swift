//
//  AWattPriceUITests.swift
//  AWattPriceUITests
//
//  Created by Léon Becker on 02.02.21.
//

import XCTest

class AWattPriceUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSettings() throws {
        let app = XCUIApplication()
        app.launch()
        
        let appStaticText = app.staticTexts
        
        let settingsTab = appStaticText["Settings"]
        XCTAssertTrue(settingsTab.exists)
        settingsTab.tap()
        
        let regionGermany = app.buttons["🇩🇪 Germany"]
        let regionAustria = app.buttons["🇦🇹 Austria"]
        XCTAssertTrue(regionGermany.exists)
        XCTAssertTrue(regionAustria.exists)
        regionAustria.tap()
        regionGermany.tap()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
