import AVFoundation
import AudioToolbox
import os.log

class AudioQueueServices {
    private var recordingQueue: AudioQueueRef?
    private var playbackQueue: AudioQueueRef?
    internal var recordingFile: AudioFileID?
    private var playbackFile: AudioFileID?
    private var isRecording = false
    private var isPlaying = false
    internal var currentPacket: Int64 = 0

    private var recordingGain: Float32 = 1.0  // 録音ゲイン（1.0 = 100%）
    private var playbackVolume: Float32 = 1.0  // 再生音量（1.0 = 100%）
    private var audioFileSize: Int64 = 0


    internal let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AudioQueueServices", category: "AudioRecording")



    private var recordingFormat: AudioStreamBasicDescription = {
        var format = AudioStreamBasicDescription()
        format.mSampleRate = 44100.0
        format.mFormatID = kAudioFormatLinearPCM
        format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        format.mBitsPerChannel = 16
        format.mChannelsPerFrame = 1
        format.mFramesPerPacket = 1
        format.mBytesPerFrame = 2
        format.mBytesPerPacket = 2
        return format
    }()

    func startRecording(filename:String) {
        guard !isRecording else {
            logger.warning("Recording already in progress")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            logger.info("Audio session setup completed")
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent(filename)

        var audioFile: AudioFileID?
        let createStatus = AudioFileCreateWithURL(audioFilePath as CFURL, kAudioFileCAFType, &recordingFormat, .eraseFile, &audioFile)
        guard createStatus == noErr else {
            logger.error("Failed to create audio file: \(createStatus)")
            return
        }
        recordingFile = audioFile
        logger.info("Audio file created successfully")

        var status = AudioQueueNewInput(&recordingFormat, audioQueueInputCallback, Unmanaged.passUnretained(self).toOpaque(), nil, nil, 0, &recordingQueue)
        guard status == noErr else {
            logger.error("Failed to create new audio queue input: \(status)")
            return
        }
        logger.info("Audio queue input created successfully")

        let bufferByteSize = deriveBufferSize(for: recordingFormat, seconds: 0.5)
        for _ in 0..<3 {
            var buffer: AudioQueueBufferRef?
            status = AudioQueueAllocateBuffer(recordingQueue!, UInt32(bufferByteSize), &buffer)
            guard status == noErr else {
                logger.error("Failed to allocate audio queue buffer: \(status)")
                return
            }
            if let buffer = buffer {
                status = AudioQueueEnqueueBuffer(recordingQueue!, buffer, 0, nil)
                guard status == noErr else {
                    logger.error("Failed to enqueue audio queue buffer: \(status)")
                    return
                }
            }
        }
        logger.info("Audio queue buffers allocated and enqueued successfully")

        status = AudioQueueStart(recordingQueue!, nil)
        guard status == noErr else {
            logger.error("Failed to start audio queue: \(status)")
            return
        }

        isRecording = true
        currentPacket = 0
        logger.info("Recording started successfully")
    }

    func stopRecording() {
        guard isRecording else {
            logger.warning("No recording in progress to stop")
            return
        }

        var status = AudioQueueStop(recordingQueue!, true)
        guard status == noErr else {
            logger.error("Failed to stop audio queue: \(status)")
            return
        }

        status = AudioQueueDispose(recordingQueue!, true)
        guard status == noErr else {
            logger.error("Failed to dispose audio queue: \(status)")
            return
        }

        status = AudioFileClose(recordingFile!)
        guard status == noErr else {
            logger.error("Failed to close audio file: \(status)")
            return
        }

        isRecording = false
        logger.info("Recording stopped successfully")
    }

    func startPlaying(filename:String) {
        guard !isPlaying else {
            logger.warning("Playback already in progress")
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent(filename)

        var audioFile: AudioFileID?
        var status = AudioFileOpenURL(audioFilePath as CFURL, .readPermission, kAudioFileCAFType, &audioFile)
        guard status == noErr else {
            logger.error("Failed to open audio file for playback: \(status), path: \(audioFilePath.path)")
            return
        }
        playbackFile = audioFile
        logger.info("Audio file opened successfully for playback")

        // ファイルサイズを取得
        var dataSize: UInt64 = 0
        var propertySize = UInt32(MemoryLayout<UInt64>.size)
        status = AudioFileGetProperty(playbackFile!, kAudioFilePropertyAudioDataByteCount, &propertySize, &dataSize)
        guard status == noErr else {
            logger.error("Failed to get audio file size: \(status)")
            return
        }
        audioFileSize = Int64(dataSize)
        logger.info("Audio file size: \(self.audioFileSize) bytes")

        var dataFormat = AudioStreamBasicDescription()
        propertySize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        status = AudioFileGetProperty(playbackFile!, kAudioFilePropertyDataFormat, &propertySize, &dataFormat)
        guard status == noErr else {
            logger.error("Failed to get audio file properties: \(status)")
            return
        }
        logger.info("Audio format - Sample Rate: \(dataFormat.mSampleRate), Channels: \(dataFormat.mChannelsPerFrame), Bits: \(dataFormat.mBitsPerChannel)")

        status = AudioQueueNewOutput(&dataFormat, audioQueueOutputCallback, Unmanaged.passUnretained(self).toOpaque(), nil, nil, 0, &playbackQueue)
        guard status == noErr else {
            logger.error("Failed to create new audio queue output: \(status)")
            return
        }
        logger.info("Audio queue output created successfully")

        currentPacket = 0  // ファイルの先頭からの再生を保証

        let bufferByteSize = deriveBufferSize(for: dataFormat, seconds: 0.5)
        for _ in 0..<3 {
            var buffer: AudioQueueBufferRef?
            status = AudioQueueAllocateBuffer(playbackQueue!, UInt32(bufferByteSize), &buffer)
            guard status == noErr else {
                logger.error("Failed to allocate audio queue buffer for playback: \(status)")
                return
            }
            if let buffer = buffer {
                readPackets(into: buffer)
            }
        }
        logger.info("Audio queue buffers allocated and filled for playback")

        status = AudioQueueStart(playbackQueue!, nil)
        guard status == noErr else {
            logger.error("Failed to start audio queue for playback: \(status)")
            return
        }

        isPlaying = true
        logger.info("Playback started successfully")
    }

    func stopPlaying() {
        guard isPlaying else {
            logger.warning("No playback in progress to stop")
            return
        }

        var status = AudioQueueStop(playbackQueue!, true)
        guard status == noErr else {
            logger.error("Failed to stop audio queue for playback: \(status)")
            return
        }

        status = AudioQueueDispose(playbackQueue!, true)
        guard status == noErr else {
            logger.error("Failed to dispose audio queue for playback: \(status)")
            return
        }

        status = AudioFileClose(playbackFile!)
        guard status == noErr else {
            logger.error("Failed to close audio file after playback: \(status)")
            return
        }

        isPlaying = false
        logger.info("Playback stopped successfully")
    }

    private func deriveBufferSize(for format: AudioStreamBasicDescription, seconds: Float64) -> Int {
        let frames = Int(format.mSampleRate * seconds)
        return frames * Int(format.mBytesPerFrame)
    }

    internal func readPackets(into buffer: AudioQueueBufferRef) {
        var numBytes = buffer.pointee.mAudioDataBytesCapacity
        var numPackets = buffer.pointee.mAudioDataBytesCapacity / recordingFormat.mBytesPerPacket

        let status = AudioFileReadPackets(playbackFile!, false, &numBytes, nil, currentPacket, &numPackets, buffer.pointee.mAudioData)
        if status != noErr {
            logger.error("Failed to read packets from audio file: \(status)")
            return
        }

        logger.info("Read \(numPackets) packets, \(numBytes) bytes, currentPacket: \(self.currentPacket)")

        if numPackets > 0 {
            buffer.pointee.mAudioDataByteSize = numBytes
            let enqueueStatus = AudioQueueEnqueueBuffer(playbackQueue!, buffer, 0, nil)
            if enqueueStatus != noErr {
                logger.error("Failed to enqueue buffer for playback: \(enqueueStatus)")
            }
            currentPacket += Int64(numPackets)
        } else {
            logger.info("Reached end of file, total bytes read: \(self.currentPacket * Int64(self.recordingFormat.mBytesPerPacket))")
            if currentPacket * Int64(recordingFormat.mBytesPerPacket) < audioFileSize {
                logger.error("Unexpected end of file. File might be corrupted.")
            }
        }
    }

    func setRecordingGain(_ gain: Float32) {
        recordingGain = max(0.0, min(gain, 1.0))  // 0.0 から 1.0 の範囲に制限
        if let queue = recordingQueue {
            var gainValue = recordingGain
            let status = AudioQueueSetParameter(queue, kAudioQueueParam_Volume, gainValue)
            if status != noErr {
                logger.error("Failed to set recording gain: \(status)")
            } else {
                logger.info("Recording gain set to \(self.recordingGain)")
            }
        }
    }

    func setPlaybackVolume(_ volume: Float32) {
        playbackVolume = max(0.0, min(volume, 1.0))  // 0.0 から 1.0 の範囲に制限
        if let queue = playbackQueue {
            var volumeValue = playbackVolume
            let status = AudioQueueSetParameter(queue, kAudioQueueParam_Volume, volumeValue)
            if status != noErr {
                logger.error("Failed to set playback volume: \(status)")
            } else {
                logger.info("Playback volume set to \(self.playbackVolume)")
            }
        }
    }
}

let audioQueueInputCallback: AudioQueueInputCallback = { inUserData, inAQ, inBuffer, inStartTime, inNumberPacketDescriptions, inPacketDescs in
    guard let inUserData = inUserData else { return }
    let audioManager = Unmanaged<AudioQueueServices>.fromOpaque(inUserData).takeUnretainedValue()

    guard let recordingFile = audioManager.recordingFile else {
        audioManager.logger.error("Recording file is nil in input callback")
        return
    }

    var inNumberPacketDescriptions = inNumberPacketDescriptions
    let writeStatus = AudioFileWritePackets(recordingFile, false, inBuffer.pointee.mAudioDataByteSize,
                                            inPacketDescs, audioManager.currentPacket, &inNumberPacketDescriptions,
                                            inBuffer.pointee.mAudioData)
    if writeStatus != noErr {
        audioManager.logger.error("Failed to write packets to file: \(writeStatus)")
    }

    audioManager.currentPacket += Int64(inNumberPacketDescriptions)

    let enqueueStatus = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    if enqueueStatus != noErr {
        audioManager.logger.error("Failed to enqueue buffer in input callback: \(enqueueStatus)")
    }
}

let audioQueueOutputCallback: AudioQueueOutputCallback = { inUserData, inAQ, inBuffer in
    guard let inUserData = inUserData else {
        print("Output callback: inUserData is nil")
        return
    }
    let audioManager = Unmanaged<AudioQueueServices>.fromOpaque(inUserData).takeUnretainedValue()
    print("Output callback called")
    audioManager.readPackets(into: inBuffer)
}
