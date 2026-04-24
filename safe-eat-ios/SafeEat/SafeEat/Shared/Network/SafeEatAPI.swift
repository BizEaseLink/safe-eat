import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return SafeEatL10n.text(L10nKey.Errors.invalidResponse)
        case let .server(_, message):
            return message
        case .invalidURL:
            return SafeEatL10n.text(L10nKey.Errors.invalidURL)
        }
    }
}

final class SafeEatAPI {
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(baseURL: URL = AppConfig.apiBaseURL) {
        self.baseURL = baseURL
        self.decoder = SafeEatAPI.makeDecoder()
    }

    func sendSMS(phone: String) async throws -> SendSmsResponse {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/sms/send",
            method: "POST",
            body: PhoneBody(phone: phone)
        )

        return try await send(request, as: SendSmsResponse.self)
    }

    func login(phone: String, code: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/login",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )

        return try await send(request, as: AuthSession.self)
    }

    func loginWithPassword(phone: String, password: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/password/login",
            method: "POST",
            body: PhonePasswordBody(phone: phone, password: password)
        )

        return try await send(request, as: AuthSession.self)
    }

    func setPassword(phone: String, code: String, password: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/password/set",
            method: "POST",
            body: PhoneCodePasswordBody(phone: phone, code: code, password: password)
        )

        return try await send(request, as: AuthSession.self)
    }

    func appleLogin(appleSub: String, displayName: String?) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/apple/login",
            method: "POST",
            body: AppleLoginBody(appleSub: appleSub, displayName: displayName)
        )

        return try await send(request, as: AuthSession.self)
    }

    func bindApplePhone(accessToken: String, phone: String, code: String) async throws -> AuthSession {
        var request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/apple/bind-phone",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: AuthSession.self)
    }

    func refreshToken(_ refreshToken: String) async throws -> RefreshTokenResponse {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/refresh-token",
            method: "POST",
            body: ["refreshToken": refreshToken]
        )

        return try await send(request, as: RefreshTokenResponse.self)
    }

    func logout(_ refreshToken: String) async throws {
        let request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/auth/logout",
            method: "POST",
            body: ["refreshToken": refreshToken]
        )
        _ = try await send(request, as: LogoutResponse.self)
    }

    func getProfile(accessToken: String) async throws -> UserProfile {
        var request = try buildRequest(path: "/v1/\(AppConfig.appCode)/me", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func updateProfile(accessToken: String, payload: UserProfileUpdatePayload) async throws -> UserProfile {
        var request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/me/profile",
            method: "PATCH",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func updateHealthProfile(accessToken: String, payload: UserHealthProfileUpdatePayload) async throws -> UserProfile {
        var request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/me/health-profile",
            method: "PATCH",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func updateAvatar(accessToken: String, imageData: Data, fileName: String = "avatar.jpg") async throws -> UserProfile {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/v1/\(AppConfig.appCode)/me/avatar", method: "PATCH")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [:],
            fileFieldName: "avatar",
            fileName: fileName,
            mimeType: "image/jpeg",
            fileData: imageData
        )

        return try await send(request, as: UserProfile.self)
    }

    func getPlans(accessToken: String) async throws -> [MembershipPlan] {
        var request = try buildRequest(path: "/v1/\(AppConfig.appCode)/membership/plans", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let response = try await send(request, as: MembershipPlanListResponse.self)
        return response.items
    }

    func createMembershipOrder(accessToken: String, payload: MembershipOrderPayload) async throws -> MembershipOrderResult {
        var request = try buildJSONRequest(
            path: "/v1/\(AppConfig.appCode)/orders",
            method: "POST",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: MembershipOrderResult.self)
    }

    func createRecognition(accessToken: String, imageData: Data, fileName: String) async throws -> RecognitionRecord {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/v1/\(AppConfig.appCode)/recognitions", method: "POST")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [:],
            fileFieldName: "image",
            fileName: fileName,
            mimeType: "image/jpeg",
            fileData: imageData
        )

        return try await send(request, as: RecognitionRecord.self)
    }

    func getRecognition(accessToken: String, recognitionId: String) async throws -> RecognitionRecord {
        var request = try buildRequest(
            path: "/v1/\(AppConfig.appCode)/recognitions/\(recognitionId)",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: RecognitionRecord.self)
    }

    @discardableResult
    func submitFeedback(
        accessToken: String,
        recognitionId: String,
        payload: FeedbackPayload
    ) async throws -> RecognitionRecord {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(
            path: "/v1/\(AppConfig.appCode)/recognitions/\(recognitionId)/feedback",
            method: "POST"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [
                "proposedName": payload.proposedName,
                "comment": payload.comment,
            ],
            fileFieldName: "evidenceImage",
            fileName: "feedback.jpg",
            mimeType: "image/jpeg",
            fileData: payload.evidenceImageData
        )

        return try await send(request, as: RecognitionRecord.self)
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        #if DEBUG
        if let url = request.url?.absoluteString {
            print("[SafeEatAPI] \(request.httpMethod ?? "REQUEST") \(url)")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[SafeEatAPI] status=\(httpResponse.statusCode)")
        #endif

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw APIError.server(
                status: httpResponse.statusCode,
                message: localizedMessage(for: serverMessage, statusCode: httpResponse.statusCode)
            )
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.server(
                status: httpResponse.statusCode,
                message: SafeEatL10n.format(L10nKey.Errors.decodeFailed, error.localizedDescription)
            )
        }
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let mergedPath = [basePath, requestPath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        components?.path = "/" + mergedPath

        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }

    private func buildJSONRequest<T: Encodable>(path: String, method: String, body: T) throws -> URLRequest {
        var request = try buildRequest(path: path, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func localizedMessage(for serverMessage: String?, statusCode: Int) -> String {
        switch serverMessage {
        case "Daily recognition quota has been used up.":
            return SafeEatL10n.text(L10nKey.Errors.requestQuotaExceeded)
        default:
            return serverMessage ?? SafeEatL10n.format(L10nKey.Errors.requestFailed, statusCode)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if let date = ISO8601DateFormatter.withFractional.date(from: raw) {
                return date
            }

            if let date = ISO8601DateFormatter.basic.date(from: raw) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(raw)")
        }
        return decoder
    }
}

private struct PhoneBody: Encodable {
    let phone: String
}

private struct PhoneCodeBody: Encodable {
    let phone: String
    let code: String
}

private struct PhonePasswordBody: Encodable {
    let phone: String
    let password: String
}

private struct PhoneCodePasswordBody: Encodable {
    let phone: String
    let code: String
    let password: String
}

private struct AppleLoginBody: Encodable {
    let appleSub: String
    let displayName: String?
}

private struct LogoutResponse: Decodable {
    let success: Bool
}

private enum ISO8601DateFormatter {
    static let withFractional: Foundation.ISO8601DateFormatter = {
        let formatter = Foundation.ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let basic: Foundation.ISO8601DateFormatter = {
        let formatter = Foundation.ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private enum MultipartFormDataBuilder {
    static func build(
        boundary: String,
        textFields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var data = Data()
        let lineBreak = "\r\n"

        for (key, value) in textFields {
            data.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            data.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        data.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!
        )
        data.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        data.append(fileData)
        data.append(lineBreak.data(using: .utf8)!)
        data.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return data
    }
}
