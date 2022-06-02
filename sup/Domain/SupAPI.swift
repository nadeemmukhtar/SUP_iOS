//
//  SupAPI.swift
//  sup
//
//  Created by Robert Malko on 4/5/20.
//  Copyright © 2020 Episode 8, Inc. All rights reserved.
//

import Foundation

struct SupAPI {
    static fileprivate let baseURL = "https://opentok.onsup.fyi"
    private static var lastSessionId: String?
    private static var lastArchiveId: String?

    static func call(json: [String: Any], completion: @escaping (Result<Call, Swift.Error>) -> ()) {
        guard let url = URL(string: "\(baseURL)/call") else { return }

        Request.Post(url: url, json: json, type: Call.self) { response in
            switch response {
            case .success(let value):
                completion(.success(value as! Call))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func callkit(json: [String: Any], completion: @escaping (Result<Call, Swift.Error>) -> ()) {
        guard let url = URL(string: "\(baseURL)/callkit") else { return }

        Request.Post(url: url, json: json, type: Call.self) { response in
            switch response {
            case .success(let value):
                completion(.success(value as! Call))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func generateToken(sessionId: String, completion: @escaping (Result<CallToken, Swift.Error>) -> ()) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/generateToken") else { return }
        urlComponents.query = "sessionId=\(sessionId)"

        guard let url = urlComponents.url else { return }

        Request.Get(url: url, type: CallToken.self) { response in
            switch response {
            case .success(let value):
                let callToken = value as! CallToken
                completion(.success(callToken))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func startArchive(sessionId: String, completion: @escaping (Result<CallArchive, Swift.Error>) -> ()) {
        if lastSessionId == sessionId { return }
        Logger.log("SupAPI.startArchive sessionId=%{public}@", log: .debug, type: .debug, sessionId)
        guard var urlComponents = URLComponents(string: "\(baseURL)/startArchive") else { return }
        urlComponents.query = "sessionId=\(sessionId)"

        guard let url = urlComponents.url else { return }

        lastSessionId = sessionId
        Request.Get(url: url, type: CallArchive.self) { response in
            switch response {
            case .success(let value):
                let callArchive = value as! CallArchive
                if AppDelegate.appState != nil {
                    DispatchQueue.main.async {
                        AppDelegate.appState!.openTokSession$.send(.archiveStarted(callArchive.id))
                    }
                }
                completion(.success(callArchive))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func stopArchive(archiveId: String, completion: @escaping (Result<CallArchive, Swift.Error>) -> ()) {
        if lastArchiveId == archiveId { return }
        Logger.log("SupAPI.stopArchive archiveId=%{public}@", log: .debug, type: .debug, archiveId)
        guard var urlComponents = URLComponents(string: "\(baseURL)/stopArchive") else { return }
        urlComponents.query = "archiveId=\(archiveId)"

        guard let url = urlComponents.url else { return }

        lastArchiveId = archiveId
        Request.Get(url: url, type: CallArchive.self) { response in
            switch response {
            case .success(let value):
                completion(.success(value as! CallArchive))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func time(completion: @escaping (Result<ApiTime, Swift.Error>) -> ()) {
        guard let url = URL(string: "\(baseURL)/time") else { return }

        Request.Get(url: url, type: ApiTime.self) { response in
            switch response {
            case .success(let value):
                completion(.success(value as! ApiTime))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    fileprivate struct Request {
        static func Get<T: Decodable>(
            url: URL,
            type: T.Type,
            completion: @escaping (Result<Decodable, Swift.Error>) -> ()
        ) {
            URLSession.shared.dataTask(with: url) { data, response, err in
                decodeData(data: data, err: err, type: type, completion: completion)
            }.resume()
        }

        static func Post<T: Decodable>(
            url: URL,
            json: [String: Any],
            type: T.Type,
            completion: @escaping (Result<Decodable, Swift.Error>) -> ()
        ) {
            var jsonData: Data
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            } catch let jsonError {
                return completion(.failure(jsonError))
            }

            session.uploadTask(with: request, from: jsonData) { data, response, err in
                decodeData(data: data, err: err, type: type, completion: completion)
            }.resume()
        }

        fileprivate static func decodeData<T: Decodable>(
            data: Data?,
            err: Error?,
            type: T.Type,
            completion: @escaping (Result<Decodable, Swift.Error>) -> ()
        ) {
            if let err = err {
                return completion(.failure(err))
            }

            do {
                let result = try JSONDecoder().decode(ApiError.self, from: data!)
                return completion(.failure(AppError.custom(errorDescription: result.error)))
            } catch {}

            do {
                let call = try JSONDecoder().decode(type, from: data!)
                return completion(.success(call))
            } catch let jsonError {
                return completion(.failure(jsonError))
            }
        }
    }

    struct ApiError: Decodable {
        let error: String
    }

    struct ApiTime: Decodable {
        let time: Double
    }

    struct Call: Decodable {
        let sessionId: String
        let token: String
        var answered: Bool?

        init(sessionId: String, token: String, answered: Bool) {
            self.sessionId = sessionId
            self.token = token
            self.answered = answered
        }
    }

    struct CallArchive: Decodable {
        let id: String
    }

    struct CallToken: Decodable {
        let token: String
    }
}

enum AppError {
    case custom(errorDescription: String?)
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .custom(let errorDescription): return errorDescription
        }
    }
}
