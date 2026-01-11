//
//  AudioRecorder.swift
//  VoicePaste
//
//  Created by Claude on 2026/1/11.
//

import AVFoundation

enum AudioRecorderError: Error {
    case permissionDenied
    case recorderFailed
}

/// Audio recorder for capturing voice input optimized for Whisper transcription.
/// Records to 16kHz mono 16-bit PCM WAV format.
@MainActor
final class AudioRecorder {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    var permissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestPermission() async -> Bool {
        let status = permissionStatus

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func startRecording() throws -> URL {
        guard permissionStatus == .authorized else {
            throw AudioRecorderError.permissionDenied
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voicepaste_recording.wav")

        // Whisper-optimized settings: 16kHz mono 16-bit PCM
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            guard audioRecorder?.record() == true else {
                throw AudioRecorderError.recorderFailed
            }
            recordingURL = url
            return url
        } catch {
            throw AudioRecorderError.recorderFailed
        }
    }

    func stopRecording() throws -> URL {
        guard let recorder = audioRecorder, let url = recordingURL else {
            throw AudioRecorderError.recorderFailed
        }

        recorder.stop()
        audioRecorder = nil
        recordingURL = nil

        return url
    }
}
