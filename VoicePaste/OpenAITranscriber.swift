//
//  OpenAITranscriber.swift
//  VoicePaste
//
//  Created by Claude on 2026/1/11.
//

import Foundation

enum TranscriptionError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    case fileTooLarge
}

/// Protocol for transcription services, enabling future streaming implementations.
protocol TranscriptionService {
    func transcribe(fileURL: URL, model: String) async throws -> String
}

extension TranscriptionService {
    func transcribe(fileURL: URL) async throws -> String {
        try await transcribe(fileURL: fileURL, model: "whisper-1")
    }
}

/// OpenAI Whisper transcription client.
final class OpenAITranscriber: TranscriptionService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/audio/transcriptions"
    private let maxFileSize: Int64 = 25 * 1024 * 1024 // 25MB limit

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribe(fileURL: URL, model: String = "whisper-1") async throws -> String {
        // Check file size
        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let size = attrs[.size] as? Int64, size > maxFileSize {
            throw TranscriptionError.fileTooLarge
        }

        guard let url = URL(string: endpoint) else {
            throw TranscriptionError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: fileURL)
        let body = buildMultipartBody(boundary: boundary, audioData: audioData, model: model, filename: fileURL.lastPathComponent)
        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranscriptionError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw TranscriptionError.apiError(message)
            }
            throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw TranscriptionError.invalidResponse
        }

        return text
    }

    private func buildMultipartBody(boundary: String, audioData: Data, model: String, filename: String) -> Data {
        var body = Data()

        // Model field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("\(model)\r\n")

        // Audio file field
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")

        // End boundary
        body.append("--\(boundary)--\r\n")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
