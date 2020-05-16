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
            playerA: .manual,
            playerB: .computer,
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
            playerA: .manual,
            playerB: .computer,
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

    func test_diskAt() {
        let s = State(input: """
            -01
            oo
            x-\n
            """)!

        XCTAssertEqual(s.diskAt(x: 0, y: 0), .light)
        XCTAssertEqual(s.diskAt(x: 1, y: 0), .light)
        XCTAssertEqual(s.diskAt(x: 0, y: 1), .dark)
        XCTAssertEqual(s.diskAt(x: 1, y: 1), nil) // 置かれていない
        XCTAssertEqual(s.diskAt(x: 2, y: 0), nil) // 範囲外
        XCTAssertEqual(s.diskAt(x: 0, y: 2), nil) // 範囲外
    }

    func test_countDisks() {
        let s = State(_10_10_and: "------x-")

        XCTAssertEqual(s.countDisks(of: .light), 10)
        XCTAssertEqual(s.countDisks(of: .dark), 11)
    }

    func test_sideWithMoreDisks() {
        var s = State(_10_10_and: "--------")
        XCTAssertEqual(s.sideWithMoreDisks(), nil)

        s = State(_10_10_and: "-------o")
        XCTAssertEqual(s.sideWithMoreDisks(), .light)

        s = State(_10_10_and: "-------x")
        XCTAssertEqual(s.sideWithMoreDisks(), .dark)
    }

    func test_flippedDiskCoordinatesByPlacingDisk() {
        let s = State(_10_10_and: "--------")
        XCTAssertEqual(s.flippedDiskCoordinatesByPlacingDisk(.light, atX: 1, y: 1), [
            Point(2, 2),
            Point(1, 2)
        ])
        XCTAssertEqual(s.flippedDiskCoordinatesByPlacingDisk(.dark, atX: 1, y: 1), [])
    }

    func test_canPlaceDisk() {
        let s = State(input: """
            -01
            x-------
            -o------
            --------
            --------
            --------
            --------
            --------
            --------\n
            """)!

        XCTAssertEqual(s.canPlaceDisk(.light, atX: 2, y: 1), false)
        XCTAssertEqual(s.canPlaceDisk(.light, atX: 2, y: 2), false)
        XCTAssertEqual(s.canPlaceDisk(.dark, atX: 2, y: 2), true)
    }

    func test_validMoves() {
        let s = State(input: """
            -01
            x-------
            -o------
            --------
            --------
            --------
            --------
            --------
            --------\n
            """)!

        XCTAssertEqual(s.validMoves(for: .light), [])
        XCTAssertEqual(s.validMoves(for: .dark), [Point(2, 2)])
    }
}

extension State {
    init(_10_10_and lastLine: String) {
        self.init(input: """
        -01
        --------
        --------
        xxxxoooo
        ooooxxxx
        ----oo--
        --------
        ------xx
        \n
        """ + lastLine)!
    }
}
