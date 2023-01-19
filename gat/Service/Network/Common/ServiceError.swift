//
//  ServiceError.swift
//  gat
//
//  Created by Vũ Kiên on 23/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import Foundation

class ServiceError: NetworkError {
    
    fileprivate var domain_: String
    fileprivate var code_: Int
    fileprivate var userInfo_: [String: String]? = nil
    
    var domain: String {
        return self.domain_
    }
    
    var code: Int {
        return self.code_
    }
    
    var userInfo: [String: String]? {
        return self.userInfo_
    }
    
    var status: StatusCode? {
        switch self.code_ {
        case 100:
            return .continue
        case 101:
            return .switchingProtocols
        case 102:
            return .processing
        case 200:
            return .ok
        case 201:
            return .created
        case 202:
            return .accepted
        case 203:
            return .nonAuthoritativeInformation
        case 204:
            return .noContent
        case 205:
            return .resetContent
        case 206:
            return .partialContent
        case 207:
            return .multiStatus
        case 208:
            return .alreadyReported
        case 226:
            return .imUsed
        case 300:
            return .multipleChoices
        case 301:
            return .movedPermanently
        case 302:
            return .found
        case 303:
            return .seeOther
        case 304:
            return .notModified
        case 305:
            return .useProxy
        case 306:
            return .switchProxy
        case 307:
            return .temporaryRedirect
        case 308:
            return .permanentRedirect
        case 400:
            return .badRequest
        case 401:
            return .unAuthorized
        case 402:
            return .paymentRequired
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 405:
            return .methodNotAllowed
        case 406:
            return .notAcceptable
        case 407:
            return .proxyAuthenticationRequired
        case 408:
            return .requestTimeout
        case 409:
            return .conflict
        case 410:
            return .gone
        case 411:
            return .lengthRequired
        case 412:
            return .preconditionFailed
        case 413:
            return .payloadTooLarge
        case 414:
            return .uriTooLong
        case 415:
            return .unsupportedMediaType
        case 416:
            return .rangeNotSatisfiable
        case 417:
            return .expectationFailed
        case 418:
            return .imATeapot
        case 421:
            return .misdirectedRequest
        case 422:
            return .unprocessableEntity
        case 423:
            return .locked
        case 424:
            return .failedDependency
        case 426:
            return .upgradeRequired
        case 428:
            return .preconditionRequired
        case 429:
            return .tooManyRequests
        case 431:
            return .requestHeaderFieldsTooLarge
        case 451:
            return .unavailableForLegalReasons
        case 500:
            return .internalServerError
        case 501:
            return .notImplemented
        case 502:
            return .badGateway
        case 503:
            return .serviceUnavailable
        case 504:
            return .gatewayTimeout
        case 505:
            return .httpVersionNotSupported
        case 506:
            return .variantAlsoNegotiates
        case 507:
            return .insufficientStorage
        case 508:
            return .loopDetected
        case 510:
            return .notExtended
        case 511:
            return .networkAuthenticationRequired
        default:
            return nil
        }
    }
    
    init(domain: String, code: Int, userInfo: [String: String]? = nil) {
        self.domain_ = domain
        self.code_ = code
        self.userInfo_ = userInfo
    }
    
    var localizedDescription: String {
        return "Error request url '\(self.domain_)' with status \(self.code_): \((self.userInfo_?["message"]) ?? "")"
    }
}
