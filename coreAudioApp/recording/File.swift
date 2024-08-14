//
//  AudioRecorder.swift
//  coreAudioApp
//
//  Created by 遠藤拓弥 on 2024/08/07.
//

import Foundation
import AudioToolbox

class AudioRecorder {
    var queue: AudioQueueRef?
    var buffers: [AudioQueueBufferRef?] = Array(repeating: nil, count: 3)

    func startRecording() {
        var dataFormat = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
            mBytesPerPacket: 16,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 2,
            mReserved: 0
        )

        let callback: AudioQueueInputCallback = { _, inAQ, inBuffer, _, _, _ in
            // ここで録音データを処理
            print("Recorded buffer size: \(inBuffer.pointee.mAudioDataByteSize)")
        }

        AudioQueueNewInput(&dataFormat, callback, nil, nil, nil, 0, &queue)

        for i in 0..<3 {
            AudioQueueAllocateBuffer(queue!, 4096, &buffers[i])
            AudioQueueEnqueueBuffer(queue!, buffers[i]!, 0, nil)
        }

        AudioQueueStart(queue!, nil)
    }

    func stopRecording() {
        AudioQueueStop(queue!, true)
        AudioQueueDispose(queue!, true)
    }
}
