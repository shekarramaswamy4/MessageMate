//
//  Payment.swift
//  Nudger-SwiftUI
//
//  Created by Shekar Ramaswamy on 8/24/23.
//

import Foundation

struct PaymentUrlRes: Codable {
    let url: String
}

struct ValidatedRes: Codable {
    let validated: Bool
}

class PaymentAPI {
    
    static func getPaymentURL(deviceId: String, completion: @escaping (Result<PaymentUrlRes, Error>) -> Void) {
        if let url = URL(string: Constants.apiUrl + "/checkout-url?device_id=" + deviceId) {
            let session = URLSession.shared
            let task = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let person = try decoder.decode(PaymentUrlRes.self, from: data)
                        completion(.success(person))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
                }
            }
            task.resume()
        } else {
            completion(.failure(NSError(domain: "InvalidURLError", code: -1, userInfo: nil)))
        }
    }
    
    static func validatePaymentCode(deviceId: String, paymentCode: String, completion: @escaping (Result<ValidatedRes, Error>) -> Void) {
        if let url = URL(string: Constants.apiUrl + "/validate?device_id=" + deviceId + "&payment_code=" + paymentCode) {
            let session = URLSession.shared
            let task = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let person = try decoder.decode(ValidatedRes.self, from: data)
                        completion(.success(person))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
                }
            }
            task.resume()
        } else {
            completion(.failure(NSError(domain: "InvalidURLError", code: -1, userInfo: nil)))
        }
    }
}
