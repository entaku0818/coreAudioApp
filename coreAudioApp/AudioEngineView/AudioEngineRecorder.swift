//
//  AudioEngineRecorder.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/15.
//

import Foundation
import AVFoundation

class AudioEngineRecorder: NSObject {
    private var audioEngine: AVAudioEngine!
    private var audioFile: AVAudioFile?
    private var inputNode: AVAudioInputNode!
    private var playerNode: AVAudioPlayerNode?
    private var isRecording = false
    private var isPlaying = false

    func startRecording(filename: String) {
        // オーディオセッションをアクティブに設定
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗しました: \(error.localizedDescription)")
            return
        }

        // AVAudioEngine の設定
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode

        let format = inputNode.outputFormat(forBus: 0)
        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: format.settings)
        } catch {
            print("オーディオファイルの作成に失敗しました: \(error.localizedDescription)")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                print("オーディオデータの書き込みに失敗しました: \(error.localizedDescription)")
            }
        }

        do {
            try audioEngine.start()
            isRecording = true
            print("録音を開始しました")
        } catch {
            print("オーディオエンジンの起動に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        if isRecording {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            isRecording = false
            print("録音を停止しました")

            // オーディオセッションを非アクティブに設定
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false)
            } catch {
                print("オーディオセッションの非アクティブ化に失敗しました: \(error.localizedDescription)")
            }
        }
    }

    func startPlaying(filename: String) {
        guard !isPlaying else {
            print("既に再生中です")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗しました: \(error.localizedDescription)")
            return
        }

        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        audioEngine.attach(playerNode!)

        let audioFilename = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            audioFile = try AVAudioFile(forReading: audioFilename)
        } catch {
            print("オーディオファイルの読み込みに失敗しました: \(error.localizedDescription)")
            return
        }

        audioEngine.connect(playerNode!, to: audioEngine.mainMixerNode, format: audioFile?.processingFormat)

        playerNode!.scheduleFile(audioFile!, at: nil)

        do {
            try audioEngine.start()
            playerNode!.play()
            isPlaying = true
            print("再生を開始しました")
        } catch {
            print("オーディオエンジンの起動に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopPlaying() {
        if isPlaying {
            playerNode?.stop()
            audioEngine.stop()
            isPlaying = false
            print("再生を停止しました")

            // オーディオセッションを非アクティブに設定
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false)
            } catch {
                print("オーディオセッションの非アクティブ化に失敗しました: \(error.localizedDescription)")
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
