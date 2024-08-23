import AVFoundation
import AudioToolbox

class AudioUnitManager {
    private(set) var audioUnit: AudioComponentInstance?
    private(set) var audioFile: AudioFileID?
    private var isRecording = false
    private var isPlaying = false
    private var recordedAudioBuffer: [Float] = []
    private(set) var playbackAudioUnit: AudioComponentInstance?

    var currentPacket: Int64 = 0

    private var audioFormat: AudioStreamBasicDescription = {
        var format = AudioStreamBasicDescription(
            mSampleRate: 44100,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 4,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 32,
            mReserved: 0
        )
        return format
    }()


    private func setupAudioUnit() {
        var audioComponentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            print("Failed to find audio component")
            return
        }

        var status = AudioComponentInstanceNew(audioComponent, &audioUnit)
        guard status == noErr else {
            print("Failed to create audio unit: \(status)")
            return
        }

        var oneFlag: UInt32 = 1
        status = AudioUnitSetProperty(audioUnit!,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Input,
                                      1,
                                      &oneFlag,
                                      UInt32(MemoryLayout<UInt32>.size))
        guard status == noErr else {
            print("Failed to enable audio input: \(status)")
            return
        }

        status = AudioUnitSetProperty(audioUnit!,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output,
                                      1,
                                      &audioFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        guard status == noErr else {
            print("Failed to set stream format: \(status)")
            return
        }

        var callbackStruct = AURenderCallbackStruct(
            inputProc: recordingCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        status = AudioUnitSetProperty(audioUnit!,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Global,
                                      0,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        guard status == noErr else {
            print("Failed to set recording callback: \(status)")
            return
        }

        print("Audio unit setup completed")
    }

    private func setupPlaybackAudioUnit() {
        var audioComponentDescription = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_RemoteIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        guard let audioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            print("Failed to find audio component for playback")
            return
        }

        var status = AudioComponentInstanceNew(audioComponent, &playbackAudioUnit)
        guard status == noErr else {
            print("Failed to create playback audio unit: \(status)")
            return
        }

        var oneFlag: UInt32 = 1
        status = AudioUnitSetProperty(playbackAudioUnit!,
                                      kAudioOutputUnitProperty_EnableIO,
                                      kAudioUnitScope_Output,
                                      0,
                                      &oneFlag,
                                      UInt32(MemoryLayout<UInt32>.size))
        guard status == noErr else {
            print("Failed to enable audio output: \(status)")
            return
        }

        status = AudioUnitSetProperty(playbackAudioUnit!,
                                      kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Input,
                                      0,
                                      &audioFormat,
                                      UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        guard status == noErr else {
            print("Failed to set stream format for playback: \(status)")
            return
        }

        var callbackStruct = AURenderCallbackStruct(
            inputProc: playbackCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )

        status = AudioUnitSetProperty(playbackAudioUnit!,
                                      kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Input,
                                      0,
                                      &callbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        guard status == noErr else {
            print("Failed to set playback callback: \(status)")
            return
        }

        status = AudioUnitInitialize(playbackAudioUnit!)
        guard status == noErr else {
            print("Failed to initialize playback audio unit: \(status)")
            return
        }

        print("Playback audio unit setup completed")
    }

    func startRecording(filename:String) {
        setupAudioUnit()
        guard !isRecording, let audioUnit = audioUnit else {
            print("Recording already in progress or audio unit not set up")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("Audio session setup completed")
        } catch {
            print("Failed to set up audio session: \(error)")
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent(filename)

        var status = AudioFileCreateWithURL(
            audioFilePath as CFURL,
            kAudioFileCAFType,
            &audioFormat,
            .eraseFile,
            &audioFile
        )
        guard status == noErr else {
            print("Failed to create audio file: \(status)")
            return
        }

        recordedAudioBuffer.removeAll()
        status = AudioOutputUnitStart(audioUnit)
        guard status == noErr else {
            print("Failed to start audio unit: \(status)")
            return
        }

        isRecording = true
        print("Recording started")
    }

    func stopRecording() {
        guard isRecording, let audioUnit = audioUnit else {
            print("No recording in progress or audio unit not set up")
            return
        }

        let status = AudioOutputUnitStop(audioUnit)
        guard status == noErr else {
            print("Failed to stop audio unit: \(status)")
            return
        }

        saveRecordingToFile()

        isRecording = false
        print("Recording stopped")
    }

    private func saveRecordingToFile() {
        guard let audioFile = audioFile else {
            print("No audio file to save")
            return
        }

        var bufferByteSize = UInt32(recordedAudioBuffer.count * MemoryLayout<Float>.size)
        var status = AudioFileWriteBytes(
            audioFile,
            false,
            0,
            &bufferByteSize,
            recordedAudioBuffer
        )
        guard status == noErr else {
            print("Failed to write audio data: \(status)")
            return
        }

        status = AudioFileClose(audioFile)
        guard status == noErr else {
            print("Failed to close audio file: \(status)")
            return
        }

        print("Audio file saved successfully")
    }

    func startPlaying(filename: String) {
        setupPlaybackAudioUnit()
        guard !isPlaying, let playbackAudioUnit = playbackAudioUnit else {
            print("Playback already in progress or playback audio unit not set up")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session for playback: \(error)")
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent(filename)

        var status = AudioFileOpenURL(
            audioFilePath as CFURL,
            .readPermission,
            kAudioFileCAFType,
            &audioFile
        )
        guard status == noErr else {
            print("Failed to open audio file for playback: \(status)")
            return
        }

        status = AudioOutputUnitStart(playbackAudioUnit)
        guard status == noErr else {
            print("Failed to start playback audio unit: \(status)")
            return
        }

        isPlaying = true
        print("Playback started")
    }

    func stopPlaying() {
        guard isPlaying, let playbackAudioUnit = playbackAudioUnit else {
            print("No playback in progress or audio unit not set up")
            return
        }

        let status = AudioOutputUnitStop(playbackAudioUnit)
        guard status == noErr else {
            print("Failed to stop audio unit for playback: \(status)")
            return
        }

        if let audioFile = audioFile {
            AudioFileClose(audioFile)
        }

        isPlaying = false
        print("Playback stopped")
    }

    func appendAudioData(_ data: [Float]) {
        recordedAudioBuffer.append(contentsOf: data)
    }
}


func recordingCallback(inRefCon: UnsafeMutableRawPointer,
                       ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                       inTimeStamp: UnsafePointer<AudioTimeStamp>,
                       inBusNumber: UInt32,
                       inNumberFrames: UInt32,
                       ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let audioUnitManager = Unmanaged<AudioUnitManager>.fromOpaque(inRefCon).takeUnretainedValue()

    guard let audioUnit = audioUnitManager.audioUnit else {
        print("Audio unit not available in recording callback")
        return kAudioUnitErr_InvalidProperty
    }

    var bufferList = AudioBufferList.allocate(maximumBuffers: 1)
    defer { bufferList.unsafeMutablePointer.deallocate() }

    bufferList[0] = AudioBuffer(
        mNumberChannels: 1,
        mDataByteSize: inNumberFrames * 4,
        mData: nil
    )

    let status = AudioUnitRender(audioUnit,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 bufferList.unsafeMutablePointer)

    if status == noErr {
        let buffer = bufferList[0]
        let samples = buffer.mData?.assumingMemoryBound(to: Float.self)
        let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size

        if let samples = samples {
            let audioData = Array(UnsafeBufferPointer(start: samples, count: count))
            audioUnitManager.appendAudioData(audioData)
        } else {
            print("Failed to get audio samples")
        }
    } else {
        print("AudioUnitRender failed with status: \(status)")
    }

    return status
}

func playbackCallback(inRefCon: UnsafeMutableRawPointer,
                      ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                      inTimeStamp: UnsafePointer<AudioTimeStamp>,
                      inBusNumber: UInt32,
                      inNumberFrames: UInt32,
                      ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    let audioUnitManager = Unmanaged<AudioUnitManager>.fromOpaque(inRefCon).takeUnretainedValue()

    guard let ioData = ioData, let audioFile = audioUnitManager.audioFile else {
        print("Audio file or ioData not available in playback callback")
        return kAudioUnitErr_InvalidProperty
    }

    var buffer = ioData.pointee.mBuffers

    var packetCount: UInt32 = inNumberFrames
    let status = AudioFileReadPacketData(audioFile,
                                         false,
                                         &buffer.mDataByteSize,
                                         nil,
                                         audioUnitManager.currentPacket,
                                         &packetCount,
                                         buffer.mData)

    if status == noErr {
        audioUnitManager.currentPacket += Int64(packetCount)

        if packetCount == 0 {
            // End of file reached
            ioActionFlags.pointee = AudioUnitRenderActionFlags(rawValue: ioActionFlags.pointee.rawValue | AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence.rawValue)
            buffer.mDataByteSize = 0

            DispatchQueue.main.async {
                audioUnitManager.stopPlaying()
            }
        }
    } else if status == kAudioFileEndOfFileError {
        print("End of audio file reached")
        DispatchQueue.main.async {
            audioUnitManager.stopPlaying()
        }
    } else {
        print("AudioFileReadPacketData failed with status: \(status)")
    }

    return noErr
}
