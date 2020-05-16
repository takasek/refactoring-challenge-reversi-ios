//
//  StateTests.swift
//  ReversiTests
//
//  Created by Yoshitaka Seki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

class StateTests: XCTestCase {

    func testDescription() {
        let state = State(
            turn: .none,
            playerControlsSegmentIndices: [1,1],
            board: [
                [nil, .dark, .light, nil],
                [.dark, .dark, .dark, .dark],
                [.light, .light, .light, .light],
                [nil, nil, nil, nil],
        ])
        XCTAssertEqual(state.description, """
            -11
            -xo-
            xxxx
            oooo
            ----\n
            """
        )
    }
}
