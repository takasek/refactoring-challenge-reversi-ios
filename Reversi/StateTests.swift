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
            players: [.manual, .computer],
            board: [
                [nil, .dark, .light, nil],
                [.dark, .dark, .dark, .dark],
                [.light, .light, .light, .light],
                [nil, nil, nil, nil],
        ])
        XCTAssertEqual(state.description, """
            -01
            -xo-
            xxxx
            oooo
            ----\n
            """
        )
    }
    func test_init_文字列から適切に復元可能() {
        let state1 = State(
            turn: .none,
            players: [.manual, .computer],
            board: [
                [nil, .dark, .light, nil],
                [.dark, .dark, .dark, .dark],
                [.light, .light, .light, .light],
                [nil, nil, nil, nil],
        ])

        let state2 = State(input: """
            -01
            -xo-
            xxxx
            oooo
            ----\n
            """)

        XCTAssertEqual(state1, state2)
    }
}
