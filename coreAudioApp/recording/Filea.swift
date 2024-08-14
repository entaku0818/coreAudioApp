//
//  Filea.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/14.
//

import Foundation
import AVFAudio
class AVFAudioRecorder: NSObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?

    func startRecording() {

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗しました: \(error.localizedDescription)")
            return
        }

        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44800,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            // エラーハンドリング
            print("録音の開始に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopRecording() {


        audioRecorder?.stop()
        audioRecorder = nil
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch {
            print("オーディオセッションの非アクティブ化に失敗しました: \(error.localizedDescription)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

import AVFoundation

class AVFAudioPlayer: NSObject, AVAudioPlayerDelegate {
    var audioPlayer: AVAudioPlayer?

    func startPlaying() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.caf")

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            // エラーハンドリング
            print("再生の開始に失敗しました: \(error.localizedDescription)")
        }
    }

    func stopPlaying() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 再生が正常に終了したときの処理
        print("再生が完了しました。")
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
