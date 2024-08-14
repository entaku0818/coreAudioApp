//
//  File3.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AudioToolbox
import UIKit

class SystemSoundExample {

    // システムサウンドID
    var soundID: SystemSoundID = 0

    // カスタムサウンドを読み込んで再生
    func playCustomSound() {
        guard let soundURL = Bundle.main.url(forResource: "customSound", withExtension: "wav") else {
            print("Sound file not found")
            return
        }

        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    // システム定義のサウンドを再生
    func playSystemSound() {
        AudioServicesPlaySystemSound(1304) // これはiOSのデフォルトの新着メッセージ音
    }

    // アラートサウンドを再生（バイブレーションを含む）
    func playAlertSound() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    // ハプティックフィードバックを生成（iOS 10以降）
    func generateHapticFeedback() {
        if #available(iOS 10.0, *) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }

    // システムサウンドの完了をハンドリング
    func playSoundWithCompletion() {
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { (soundID, clientData) -> Void in
            print("Sound finished playing")
        }, nil)

        AudioServicesPlaySystemSound(soundID)
    }

    // リソースを解放
    func disposeSound() {
        AudioServicesDisposeSystemSoundID(soundID)
    }
}


