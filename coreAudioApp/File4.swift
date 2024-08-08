//
//  File4.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AVFoundation

class AudioUploader {
    private let engine = AVAudioEngine()
    private let serverURL = URL(string: "https://your-server.com/upload")!
    private var isRecording = false

    func startRecordingAndUploading() {
        let input = engine.inputNode
        let bus = 0
        let inputFormat = input.inputFormat(forBus: bus)

        input.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            self?.processBuffer(buffer)
        }

        do {
            try engine.start()
            isRecording = true
            print("Recording and uploading started")
        } catch {
            print("Could not start engine: \(error.localizedDescription)")
        }
    }

    func stopRecordingAndUploading() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        isRecording = false
        print("Recording and uploading stopped")
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frames = buffer.frameLength
        let channelCount = buffer.format.channelCount

        var data = Data()
        for frame in 0..<Int(frames) {
            for channel in 0..<Int(channelCount) {
                let value = channelData[channel][frame]
                data.append(contentsOf: withUnsafeBytes(of: value) { Array($0) })
            }
        }

        uploadData(data)
    }

    private func uploadData(_ data: Data) {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("audio/raw", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Upload successful")
            }
        }
        task.resume()
    }
}
