//
//  APIKeyStore.swift
//  VoicePaste
//
//  Created by Claude on 2026/1/11.
//

import Foundation

enum APIKeyStoreError: Error {
    case directoryCreationFailed
    case writeFailed
    case deleteFailed
}

/// File-based API key storage in Application Support directory.
/// Stores API key in plaintext with owner-only permissions to avoid Keychain prompts.
enum APIKeyStore {
    private static let appName = "VoicePaste"
    private static let apiKeyFileName = "api_key"
    private static let promptFileName = "prompt"

    private static var storageDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(appName)
    }

    private static var apiKeyURL: URL {
        storageDirectory.appendingPathComponent(apiKeyFileName)
    }

    private static var promptURL: URL {
        storageDirectory.appendingPathComponent(promptFileName)
    }

    static func saveAPIKey(_ key: String) throws {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            try deleteAPIKey()
            return
        }

        // Ensure directory exists
        let directory = storageDirectory
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw APIKeyStoreError.directoryCreationFailed
            }
        }

        // Write atomically with owner-only permissions
        let fileURL = apiKeyURL
        do {
            try trimmedKey.write(to: fileURL, atomically: true, encoding: .utf8)
            // Set file permissions to owner read/write only (0600)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            throw APIKeyStoreError.writeFailed
        }
    }

    static func loadAPIKey() -> String? {
        let fileURL = apiKeyURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func deleteAPIKey() throws {
        let fileURL = apiKeyURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw APIKeyStoreError.deleteFailed
        }
    }

    // MARK: - Prompt Storage

    static func savePrompt(_ prompt: String) throws {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            try deletePrompt()
            return
        }

        // Ensure directory exists
        let directory = storageDirectory
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw APIKeyStoreError.directoryCreationFailed
            }
        }

        // Write atomically with owner-only permissions
        let fileURL = promptURL
        do {
            try trimmedPrompt.write(to: fileURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            throw APIKeyStoreError.writeFailed
        }
    }

    static func loadPrompt() -> String? {
        let fileURL = promptURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func deletePrompt() throws {
        let fileURL = promptURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw APIKeyStoreError.deleteFailed
        }
    }
}
