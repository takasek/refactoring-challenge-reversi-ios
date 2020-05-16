//
//  Repository.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}
protocol DataStore {
    mutating func write(string: String) throws
    func read() throws -> String
    func readError() -> Error
}
class DataStoreImpl: DataStore {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    func write(string: String) throws {
        do {
            try string.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    func readError() -> Error {
        FileIOError.read(path: path, cause: nil)
    }
}

class Repository {
    private(set) var dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func saveGame(state: State) throws {
        try dataStore.write(string: state.description)
    }

    func loadGame() throws -> State {
        guard let state = State(input: try dataStore.read()) else {
            throw dataStore.readError()
        }
        return state
    }
}
