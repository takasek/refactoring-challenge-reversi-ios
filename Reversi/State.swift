//
//  State.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

struct State {
    let turn: Disk?
    let players: [Player]
    let board: [[Disk?]]

    var description: String {
        var output: String = ""
        output += turn.symbol
        output += players.reduce("") { $0 + $1.rawValue.description }
        output += "\n"

        for line in board {
            for disk in line {
                output += disk.symbol
            }
            output += "\n"
        }
        return output
    }
}

extension State {
    init(turn: Disk?, playerControls: [UISegmentedControl], boardView: BoardView) {
        self.turn = turn
        self.players = Disk.sides
            .map { playerControls[$0.index].selectedSegmentIndex }
            .map { Player(rawValue: $0)! }

        var board: [[Disk?]] = []
        for y in boardView.yRange {
            var line: [Disk?] = []
            for x in boardView.xRange {
                line.append(boardView.diskAt(x: x, y: y))
            }
            board.append(line)
        }
        self.board = board
    }
}
