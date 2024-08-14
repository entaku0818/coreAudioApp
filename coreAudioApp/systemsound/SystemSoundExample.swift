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


    enum SystemSound: UInt32, CaseIterable {
        case newMail = 1000
        case mailSent = 1001
        case voicemailReceived = 1002
        case smsReceived = 1003
        case calendarAlert = 1005
        case lowPower = 1006
        case smsReceived1 = 1007
        case smsReceived2 = 1008
        case smsReceived3 = 1009
        case smsReceived4 = 1010
        case smsReceivedVibrate = 1011
        case smsReceived5 = 1012
        case smsReceived6 = 1013
        case tweetSent = 1017
        case anticipate = 1020
        case bloom = 1021
        case calypso = 1022
        case chooChoo = 1023
        case descent = 1024
        case fanfare = 1025
        case ladder = 1026
        case minuet = 1027
        case newsFlash = 1028
        case noir = 1029
        case sherwoodForest = 1030
        case spell = 1031
        case suspense = 1032
        case telegraph = 1033
        case tiptoes = 1034
        case typewriters = 1035
        case update = 1036
        case ussdAlert = 1050
        case simToolkitTone = 1051
        case pinEntered = 1052
        case lockSound = 1100
        case unlockSound = 1101
        case failedUnlock = 1102
        case keyPressedTock = 1103
        case keyPressed1 = 1104
        case keyPressed2 = 1105
        case keyPressed3 = 1106
        case lockSoundTink = 1107
        case cameraShutter = 1108
        case shakeToShuffle = 1109
        case jblBegin = 1110
        case jblConfirm = 1111
        case jblCancel = 1112
        case beginRecording = 1113
        case endRecording = 1114
        case jblAmbiguous = 1115
        case jblNoMatch = 1116
        case beginVideoRecording = 1117
        case endVideoRecording = 1118
        case vcInvitationAccepted = 1150
        case vcRinging = 1151
        case vcEnded = 1152
        case vcCallWaiting = 1153
        case vcCallUpgrade = 1154
        case touchTone1 = 1200
        case touchTone2 = 1201
        case touchTone3 = 1202
        case touchTone4 = 1203
        case touchTone5 = 1204
        case touchTone6 = 1205
        case touchTone7 = 1206
        case touchTone8 = 1207
        case touchTone9 = 1208
        case touchTone10 = 1209
        case touchToneStar = 1210
        case touchTonePound = 1211
        case headUnlockedTock = 1254
        case headLockedTock = 1255
        case systemSoundPreview = 1300
        case smsReceivedSelection = 1301
        case anticipation = 1302
        case bloomUp = 1303
        case newMessage = 1304
        case triTone = 1305
        case note = 1306
        case drumRoll = 1307
        case bellTower = 1308
        case orchestral = 1309
        case telegraphUp = 1310
        case anticipatoryTone = 1311
        case smsReceived3Tone = 1312
        case smsReceived6Tone = 1313
        case smsReceived2Tone = 1314
        case smsReceived1Tone = 1315
        case calendarAlertSelection = 1316
        case koto = 1317
        case smsSentSelection = 1318
        case telegraphDown = 1319
        case anticipatoryChime = 1320
        case triangulate = 1321
        case ussdTone = 1322
        case twitterSentTone = 1323
        case anticipationTone = 1324
        case minuetTone = 1325
        case noirTone = 1326
        case ussdAlertTone = 1327
        case descentTone = 1328
        case bloomDown = 1329
        case calypsoTone = 1330
        case updateTone = 1331
        case sherwoodTone = 1332
        case minuetChime = 1333
        case ladderTone = 1334
        case anticipationUp = 1335
        case bloomTone = 1336
        case telegraphTone = 1337
        case anticipationChime = 1338
        case bloomUpTone = 1339
        case anticipatoryToneUp = 1340
        case anticipationChimeTone = 1341
        case suspenseTone = 1342
        case anticipationChimeSelection = 1343
        case noirToneSelection = 1344
        case calypsoChime = 1345
        case telegraphToneSelection = 1346
        case tiptoesTone = 1347
        case drumRollTone = 1348
        case orchestralTone = 1349
        case noteTone = 1350
        case anticipationChimeToneSelection = 1351
        case noirChime = 1352
        case suspenseChime = 1353
        case bloomUpToneSelection = 1354
        case bellTowerTone = 1355
        case anticipationChimeToneUp = 1356
        case suspenseChimeTone = 1357
        case telegraphChime = 1358
        case anticipationToneUpSelection = 1359
        case noirToneUp = 1360
        case noirToneUpSelection = 1361
        case anticipationChimeToneUpSelection = 1362
        case noirChimeTone = 1363
        case suspenseToneUp = 1364
    }


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
    func playSystemSound(sound:SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue) // これはiOSのデフォルトの新着メッセージ音
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
    private func disposeSound() {
        AudioServicesDisposeSystemSoundID(soundID)
    }
}


