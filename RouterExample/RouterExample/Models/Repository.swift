//
//  Repository.swift
//  RouterExample
//
//  Created by Freek Zijlmans on 23/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import Foundation

// MARK: -
struct Owner: Decodable, Identifiable {
    let avatarUrl: URL
    let id: Int
    let login: String
}

// MARK: -
struct Repository: Decodable, Identifiable {
    let forks: Int
    let fullName: String
    let id: Int
    let language: String?
    let name: String
    let owner: Owner
    let stargazersCount: Int
}
