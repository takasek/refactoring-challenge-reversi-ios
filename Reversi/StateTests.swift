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

    func test_countDisks() {
        // TODO: Stateのメソッドとする
        let v = BoardView()
        try! v.applyWithoutAnimation(State(_10_10_and: "------x-").board)

        XCTAssertEqual(v.countDisks(of: .light), 10)
        XCTAssertEqual(v.countDisks(of: .dark), 11)
    }

    func test_sideWithMoreDisks() {
        // TODO: Stateのメソッドとする
        let v = BoardView()
        try! v.applyWithoutAnimation(State(_10_10_and: "--------").board)
        XCTAssertEqual(v.sideWithMoreDisks(), nil)

        try! v.applyWithoutAnimation(State(_10_10_and: "-------o").board)
        XCTAssertEqual(v.sideWithMoreDisks(), .light)

        try! v.applyWithoutAnimation(State(_10_10_and: "-------x").board)
        XCTAssertEqual(v.sideWithMoreDisks(), .dark)
    }

    func test_canPlaceDisk() {
        // TODO: Stateのメソッドとする
        let v = BoardView()
        try! v.applyWithoutAnimation(State(input: """
            -01
            x-------
            -o------
            --------
            --------
            --------
            --------
            --------
            --------\n
            """)!.board)

        XCTAssertEqual(v.canPlaceDisk(.light, atX: 2, y: 1), false)
        XCTAssertEqual(v.canPlaceDisk(.light, atX: 2, y: 2), false)
        XCTAssertEqual(v.canPlaceDisk(.dark, atX: 2, y: 2), true)
    }

    func test_validMoves() {
        // TODO: Stateのメソッドとする
        let v = BoardView()
        try! v.applyWithoutAnimation(State(input: """
            -01
            x-------
            -o------
            --------
            --------
            --------
            --------
            --------
            --------\n
            """)!.board)

        XCTAssertEqual(v.validMoves(for: .light), [])
        XCTAssertEqual(v.validMoves(for: .dark), [Point(2, 2)])
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
