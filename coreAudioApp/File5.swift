//
//  File5.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AVFAudio
class AudioEffectProcessor {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    // エフェクトノード
    private let reverb = AVAudioUnitReverb()
    private let delay = AVAudioUnitDelay()
    private let distortion = AVAudioUnitDistortion()
    private let eq = AVAudioUnitEQ(numberOfBands: 3)

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        // ノードを追加
        engine.attach(player)
        engine.attach(reverb)
        engine.attach(delay)
        engine.attach(distortion)
        engine.attach(eq)

        // ノードを接続
        engine.connect(engine.inputNode, to: reverb, format: nil)
        engine.connect(reverb, to: delay, format: nil)
        engine.connect(delay, to: distortion, format: nil)
        engine.connect(distortion, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)

        // エフェクトの初期設定
        setupEffects()
    }

    private func setupEffects() {
        // リバーブ
        reverb.loadFactoryPreset(.largeHall2)
        reverb.wetDryMix = 50

        // ディレイ
        delay.delayTime = 0.5
        delay.feedback = 50
        delay.lowPassCutoff = 15000
        delay.wetDryMix = 50

        // ディストーション
        distortion.loadFactoryPreset(.multiEcho1)
        distortion.wetDryMix = 50

        // イコライザー
        eq.bands[0].frequency = 80
        eq.bands[0].gain = 0
        eq.bands[1].frequency = 1000
        eq.bands[1].gain = 0
        eq.bands[2].frequency = 10000
        eq.bands[2].gain = 0
    }

    func startProcessing() {
        do {
            try engine.start()
            print("Audio processing started")
        } catch {
            print("Could not start engine: \(error.localizedDescription)")
        }
    }

    func stopProcessing() {
        engine.stop()
        print("Audio processing stopped")
    }

    // エフェクトのパラメータを調整するメソッド
    func setReverbWetDryMix(_ value: Float) {
        reverb.wetDryMix = value
    }

    func setDelayTime(_ value: TimeInterval) {
        delay.delayTime = value
    }

    func setDistortionWetDryMix(_ value: Float) {
        distortion.wetDryMix = value
    }

    func setEQBandGain(band: Int, gain: Float) {
        if band >= 0 && band < eq.bands.count {
            eq.bands[band].gain = gain
        }
    }
}
