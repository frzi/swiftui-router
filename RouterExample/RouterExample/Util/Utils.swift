//
//  Utils.swift
//  RouterExample
//
//  Created by Freek Zijlmans on 23/08/2019.
//  Copyright © 2019 Freek Zijlmans. All rights reserved.
//

import Foundation

public struct EmptyBody: Encodable {}

/// A very, very simple, barebones function to initialize an URLSessionDataTask.
public func fetch<Response: Decodable>(url: URL, handler: @escaping (Result<Response, Error>) -> Void) -> URLSessionDataTask {
    var request = URLRequest(url: url)
    request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let data = data {
            do {
                let response = try decoder.decode(Response.self, from: data)
                handler(.success(response))
            }
            catch {
                handler(.failure(error))
            }
        }
        else if let error = error {
            handler(.failure(error))
        }
    }
    
    task.resume()
    
    return task
}

// MARK: -
/// Performs the fetcher and caches the result.
final class RepositoriesFetcher: ObservableObject {

    @Published var repositories: [Repository] = []
    @Published var isBusy = false
    
    private weak var task: URLSessionDataTask?
    
    func request(user: String) {
        isBusy = true
        task?.cancel()
        
        guard let url = URL(string: "https://api.github.com/users/" + user + "/repos?sort=updated&type=all") else {
            return
        }
        
        task = fetch(url: url) { (result: Result<[Repository], Error>) in
            DispatchQueue.main.async {
                if case .success(let repositories) = result {
                    self.repositories = repositories
                }
                else if case .failure(let error) = result {
                    print(error)
                }
                
                self.isBusy = false
            }
        }
    }
}
