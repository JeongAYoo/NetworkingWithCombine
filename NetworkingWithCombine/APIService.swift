//
//  APIService.swift
//  NetworkingWithCombine
//
//  Created by Jade Yoo on 2023/06/28.
//

import Foundation
import Combine
import Alamofire
 
struct TestNetworkResponse: Codable {
    var id: Int
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "hashValue"
        case name = "originalName"
    }
}

// 1. Error 타입 정의
enum APIError: Error {
    case http(ErrorData)
    case unknown
}
 
// 2. ErrorData 안에 들어갈 정보 선언
struct ErrorData: Codable {
    var message: String
    
    enum CodingKeys: String, CodingKey {
        case message = "errorMessage"
    }
}
 
struct APIService {
    // 4. Resonse 선언
    struct Response<T> {
        let value: T
        let response: URLResponse
    }
 
    func run<T: Decodable>(_ request: DataRequest, _ decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Response<T>, APIError> {
        return request.validate(statusCode: 200..<300).publishData().tryMap { result -> Response<T> in
            debugPrint(result)
            if let error = result.error {
                if let errorData = result.data {
                    let value = try decoder.decode(ErrorData.self, from: errorData)
                    throw APIError.http(value)
                }
                else {
                    throw error
                }
            }
            if let data = result.data {
            // 응답이 성공이고 result가 있을 때
                let value = try decoder.decode(T.self, from: data)
                return Response(value: value, response: result.response!)
            } else {
            // 응답이 성공이고 result가 없을 때 Empty를 리턴
                return Response(value: Empty.emptyValue() as! T, response: result.response!)
            }
        }
        .mapError({ (error) -> APIError in
            if let apiError = error as? APIError {
                return apiError
            } else {
                return .unknown
            }
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

enum ApiClient {
    static let agent = APIService()
    static let base = "https://jayden-bin.kro.kr"
    static let header: HTTPHeaders = [
        "Content-Type" : "application/json"
    ]
 
    static func postUsername(username: String) -> AnyPublisher<TestNetworkResponse, APIError> {
        var urlComponents = URLComponents(string: base + "/test")!
        let parameter: Parameters = [
            "name" : username
        ]

        let request = AF.request(urlComponents.url!, method: .post, parameters: parameter, encoding: JSONEncoding.prettyPrinted, headers: header)
        
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}

