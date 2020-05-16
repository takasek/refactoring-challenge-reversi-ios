//
//  RepositoryTests.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

class RepositoryTests: XCTestCase {
    class DummyDataStore: DataStore {
        var string: String

        init() { string = "" }
        func write(string: String) throws { self.string = string }
        func read() throws -> String { string }
        func readError() -> Error { NSError() }
    }

    var dataStore: DummyDataStore!
    var repository: Repository!

    override func setUp() {
        dataStore = DummyDataStore()
        repository = Repository(dataStore: dataStore)
    }

    func test_loadGame() {
        let playerControls: [UISegmentedControl] = [0,1].map { _ in
            let x = UISegmentedControl(items: ["0", "1"])
            x.selectedSegmentIndex = 0
            return x
        }
        let boardView = BoardView()

        // 初期状態の確認
        XCTAssertEqual(
            State(turn: .none, playerControls: playerControls, boardView: boardView).description,
            """
            -00
            --------
            --------
            --------
            ---ox---
            ---xo---
            --------
            --------
            --------\n
            """
        )

        // ロード後の確認
        dataStore.string = """
        x11
        -xo--xo-
        xxxxxxxx
        oooooooo
        --------
        xxxxxxxx
        oooooooo
        --------
        -xo--xo-\n
        """

        let turn = try! repository.loadGame(playerControls: playerControls, boardView: boardView)

        XCTAssertEqual(
            State(turn: turn, playerControls: playerControls, boardView: boardView).description,
            dataStore.string
        )
    }
}
