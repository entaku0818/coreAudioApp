//
//  File２.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AudioToolbox

class AudioUnitPlayer {
    var audioUnit: AudioUnit?

    func setupAudioUnit() {
        var componentDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_DefaultOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let component = AudioComponentFindNext(nil, &componentDesc) else { return }
        AudioComponentInstanceNew(component, &audioUnit)

        var renderCallback = AURenderCallbackStruct(
            inputProc: { _, _, _, _, inNumberFrames, ioData in
                // ここでオーディオデータを生成
                let buffer = ioData!.pointee.mBuffers
                let data = buffer.mData!.assumingMemoryBound(to: Float.self)
                for i in 0..<Int(inNumberFrames) {
                    data[i] = sin(Float(i) * 0.1) * 0.5
                }
                return noErr
            },
            inputProcRefCon: nil
        )

        AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, UInt32(MemoryLayout<AURenderCallbackStruct>.size))

        AudioUnitInitialize(audioUnit!)
    }

    func startPlaying() {
        AudioOutputUnitStart(audioUnit!)
    }

    func stopPlaying() {
        AudioOutputUnitStop(audioUnit!)
    }
}

