//
//  AVAQAudioController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AVFoundation

class APGAudioController {
    
    //MARK:Static Properties
    static let instance = APGAudioController()
    static let MAX_BUFFERS = 2

    //MARK:Class Instance Properties
    let audioSessionManager = AudioSessionManager.instance

    var audioGraph = AUGraph()
    var outputUnit = AudioUnit()
    var mClientFormat:AudioStreamBasicDescription = AudioStreamBasicDescription()
    var mOutputFormat:AudioStreamBasicDescription = AudioStreamBasicDescription()
    var bufferData = SourceAudioBufferData()
    var inRefConType = UnsafeMutablePointer<SourceAudioBufferData>.self
    var currentFileUrl:NSURL!
    var nextFileUrl:NSURL!
    
    //MARK:Initializer
    init() {
        currentFileUrl = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Track1", ofType: "mp4")!)
        nextFileUrl = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Track2", ofType: "mp4")!)
    }
    
    //MARK:AudioController protocol items
    var delegate:AudioControllerDelegate!
    
    var audioTrackIsLoaded:Bool {
        return false
    }
    
    var currentPlaybackTime:Double = 1.0
    

    func play() -> Bool {
        var result = noErr
        result = AUGraphStart(audioGraph)
        if(resultIsError(result, forFunction: "AUGraphStart")) { return false }
        return true
    }
    
    func pause() -> Bool {
        var isRunning:Boolean = 0
        var result = noErr
        result = AUGraphIsRunning(audioGraph, &isRunning)
        if(resultIsError(result, forFunction: "AUGraphIsRunning")) { return false }
        
        if(isRunning != 0) {
            result = AUGraphStop(audioGraph)
            if(resultIsError(result, forFunction: "AUGraphStop")) { return false }
            return true
        }
        
        return true
    }
    
    func loadItem(url:NSURL) -> Bool {
        currentFileUrl = url
        loadAudioFile(url)
        return true
    }

    //MARK:Class Functions
    func initializeAudioGraph() {
        var outputNode:AUNode = 0
//        var eqNode:AUNode!
        
        
        mClientFormat.setCanonical(2, interleaved: true, forAudioUnit:false)
        mClientFormat.mSampleRate = audioSessionManager.deviceSampleRate
        
        mOutputFormat.setCanonical(2, interleaved: false, forAudioUnit: true)
        mOutputFormat.mSampleRate = audioSessionManager.deviceSampleRate
        
        var result:OSStatus = noErr
        
        result = NewAUGraph(&audioGraph)
        if(resultIsError(result, forFunction:"NewAUGraph")) { return }
        
        var output_desc = AudioComponentDescription(inType: kAudioUnitType_Output, inSubType: kAudioUnitSubType_RemoteIO, inManufacturer: kAudioUnitManufacturer_Apple)
        result = AUGraphAddNode(audioGraph, &output_desc, &outputNode)
        if(resultIsError(result, forFunction:"AUGraphAddNode - output")) { return }
        
        result = AUGraphOpen(audioGraph)
        if(resultIsError(result, forFunction:"AUGraphOpen")) { return }
        
        result = AUGraphNodeInfo(audioGraph, outputNode, nil, &outputUnit)
        if(resultIsError(result, forFunction:"AUGraphNodeInfo")) { return }
        
        let numBuses:UInt32 = 1
        
        for (var i:UInt32 = 0; i<numBuses; ++i) {
            var renderCallbackStruct = AURenderCallbackStruct()
            renderCallbackStruct.inputProc = AURenderCallback(getCOpaquePointer(APGAudioController.renderCallback))
            renderCallbackStruct.inputProcRefCon = getVoidPointer(&bufferData)
            
            result = AUGraphSetNodeInputCallback(audioGraph, outputNode, i, &renderCallbackStruct)
            if(resultIsError(result, forFunction:"AUGraphSetNodeInputCallback")) { return }
            
            result = AudioUnitSetProperty(outputUnit, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat),
                AudioUnitScope(kAudioUnitScope_Input), AudioUnitElement(i), &mClientFormat, UInt32(sizeofValue(mClientFormat)))
            if(resultIsError(result, forFunction:"AudioUnitSetProperty - output unit")) { return }
        }
        
        result = AUGraphAddRenderNotify(audioGraph, AURenderCallback(getCOpaquePointer(APGAudioController.renderNotification)), &bufferData)
        if(resultIsError(result, forFunction:"AUGraphAddRenderNotify")) { return }
        
        result = AUGraphInitialize(audioGraph)
        if(resultIsError(result, forFunction:"AUGraphInitialize")) { return }
        
        CAShow(unsafeBitCast(audioGraph, UnsafeMutablePointer<Void>.self))
        
        loadAudioFile(currentFileUrl)
        
    }
    
    private func resultIsError(var result:OSStatus, forFunction:String) -> Bool {
        if(result != noErr) {
//            let f3 = withUnsafeMutablePointer(&result, {(ptr:UnsafeMutablePointer<OSStatus>) -> NSString in
//                var uintPtr = unsafeBitCast(ptr, UnsafeMutablePointer<UInt>.self)
//                var cPtr = unsafeBitCast(ptr, UnsafeMutablePointer<[CChar]>.self)
//                return NSString(format:"%ld %08X %4.4s\n", ptr.memory, uintPtr.memory, cPtr)
//            })
            Logger.debug("result in error from \(forFunction): \(CoreAudioHelper.checkError(result))")
            return true
        }
        return false
    }

    
    private func getUnsafeMutablePointer<T>(var object:T) -> UnsafeMutablePointer<T> {
        return withUnsafeMutablePointer(&object, { return $0 })
    }
    
    private func getUnsafeMutablePointer<T>(#cPtr:COpaquePointer) -> UnsafeMutablePointer<T> {
        return unsafeBitCast(cPtr, UnsafeMutablePointer<T>.self)
    }
    
    private func getCOpaquePointer<T>(object:T) -> COpaquePointer {
        return COpaquePointer(getUnsafeMutablePointer(object))
    }
    
    private func getVoidPointer(pointer:UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
        return pointer
    }
    
    static func renderCallback(inRefCon:UnsafeMutablePointer<Void>,
        ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp:UnsafePointer<AudioTimeStamp>,
        inBusNumber:UInt32,
        inNumberFrames:UInt32,
        ioData:UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
            
            let apgAudioController = APGAudioController.instance
            
            let sourceData:SourceAudioBufferData = unsafeBitCast(inRefCon, apgAudioController.inRefConType).memory
            let ioDataPtr = UnsafeMutableAudioBufferListPointer(ioData)
            
            var inData = sourceData.soundBuffer.data
            var outData = ioDataPtr[0].mData
            
            let sample:UInt32 = sourceData.frameNum * sourceData.soundBuffer.asbd.mChannelsPerFrame
            let inDataPtr = withUnsafePointer(&inData![Int(sample)], {return $0} )
            
            if((sourceData.frameNum + inNumberFrames) > sourceData.soundBuffer.numFrames) {
                let offset:UInt32 = (sourceData.frameNum + inNumberFrames) - sourceData.soundBuffer.numFrames
                if(offset < inNumberFrames) {
                    //copy the last bit of source
                    silenceData(ioDataPtr)

                    memcpy(outData, inDataPtr, Int((inNumberFrames - offset) * sourceData.soundBuffer.asbd.mBitsPerChannel))
                    return noErr
                } else {
                    silenceData(ioDataPtr)
                    ioActionFlags.memory |= AudioUnitRenderActionFlags(kAudioUnitRenderAction_OutputIsSilence)
                    return noErr
                }
            }
            
            memcpy(outData, inDataPtr, Int(ioDataPtr[0].mDataByteSize))
            
            return noErr
            
    }
    
    static func silenceData(inData:UnsafeMutableAudioBufferListPointer) {
        for buffer in inData {
            memset(buffer.mData, Int32(0) , Int(buffer.mDataByteSize))
        }
    }
    
    static func renderNotification(inRefCon:UnsafeMutablePointer<Void>,
        ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp:UnsafePointer<AudioTimeStamp>,
        inBusNumber:UInt32,
        inNumberFrames:UInt32,
        ioData:UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
            let apgAudioController = APGAudioController.instance
            var sourceData:SourceAudioBufferData = unsafeBitCast(inRefCon, apgAudioController.inRefConType).memory
            Logger.debug("ioActionFlags: \(ioActionFlags.memory)")
            let postRenderFlag = AudioUnitRenderActionFlags(kAudioUnitRenderAction_PostRender)
            Logger.debug("postRenderFlag: \(postRenderFlag)")
            
            let flag = ioActionFlags.memory & postRenderFlag
            Logger.debug("ioActionFlags & postRenderFlag: \(flag)")
            if(flag != 0) {
                sourceData.frameNum += inNumberFrames
                if(sourceData.frameNum >= sourceData.maxNumFrames) {
                    sourceData.frameNum = 0
                    apgAudioController.loadAudioFile(apgAudioController.nextFileUrl)
                    apgAudioController.currentFileUrl = apgAudioController.nextFileUrl
                }
            }
            
            
            return noErr
    }
    
    private func loadAudioFile(url:NSURL) {
        bufferData.frameNum = 0
        bufferData.maxNumFrames = 0
        Logger.debug("attempting to load audio file \(url.relativePath!)")
        
//        var mClientFormat = AudioStreamBasicDescription()
//        mClientFormat.setCanonical(2, interleaved: true, forAudioUnit: false)
//        mClientFormat.mSampleRate = audioSessionManager.deviceSampleRate
        
        let cfurl = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, url.relativePath as! CFStringRef, CFURLPathStyle.CFURLPOSIXPathStyle, 0)
        
        var extendedAudioFileRef = ExtAudioFileRef()
        
        var result = noErr
        result = ExtAudioFileOpenURL(cfurl, &extendedAudioFileRef)
        if(resultIsError(result, forFunction: "ExtAudioFileOpenURL")) {return}
        
        var fileFormat = AudioStreamBasicDescription()
        var propSize = sizeOf32(fileFormat)
        
        result = ExtAudioFileGetProperty(extendedAudioFileRef, ExtAudioFilePropertyID(kExtAudioFileProperty_FileDataFormat), &propSize, &fileFormat)
        if(resultIsError(result, forFunction: "ExtAudioFileGetProperty - kExtAudioFileProperty_FileDataFormat")) {return}
        
        result = ExtAudioFileSetProperty(extendedAudioFileRef, ExtAudioFilePropertyID(kExtAudioFileProperty_ClientDataFormat), sizeOf32(mClientFormat), &mClientFormat)
        if(resultIsError(result, forFunction: "ExtAudioFileSetProperty")) {return}
        
        var numFrames:UInt64 = 0
        propSize = sizeOf32(numFrames)
        result = ExtAudioFileGetProperty(extendedAudioFileRef, ExtAudioFilePropertyID(kExtAudioFileProperty_FileLengthFrames), &propSize, &numFrames)
        if(resultIsError(result, forFunction: "ExtAudioFileGetProperty - kExtAudioFileProperty_FileLengthFrames") || numFrames == 0) {return}
        
        bufferData.maxNumFrames = UInt32(numFrames)
        
        bufferData.soundBuffer.numFrames = UInt32(numFrames)
        bufferData.soundBuffer.asbd = mClientFormat
        
        var samples:UInt32 = bufferData.soundBuffer.numFrames * bufferData.soundBuffer.asbd.mChannelsPerFrame
        bufferData.soundBuffer.data = [AudioSampleType](count: Int(samples), repeatedValue: AudioSampleType(0))
        
        var audioBuffer = AudioBuffer(mNumberChannels: bufferData.soundBuffer.asbd.mChannelsPerFrame,
            mDataByteSize: (samples * sizeOf32(AudioSampleType)),
            mData: &bufferData.soundBuffer.data!)
        var bufList = AudioBufferList(mNumberBuffers: 1, mBuffers: audioBuffer)
        var bufListPtr = UnsafeMutableAudioBufferListPointer(&bufList)
        var numPackets = UInt32(numFrames)
        result = ExtAudioFileRead(extendedAudioFileRef, &numPackets, bufListPtr.unsafeMutablePointer)
        if(resultIsError(result, forFunction: "ExtAudioFileRead. numPackets:\(numPackets)")) {
//            free(&bufferData.soundBuffer.data!)
            bufferData.soundBuffer.data = [AudioSampleType]()
            return
        }
        
        ExtAudioFileDispose(extendedAudioFileRef)
        if(resultIsError(result, forFunction: "ExtAudioFileDispose")) {return}
        
        Logger.debug("audio file \(url.absoluteString) has been fully loaded")
    }

}

//MARK: Supporting Types
extension APGAudioController {
    //MARK:SoundBuffer
    struct  SoundBuffer {
        var numFrames:UInt32 = 0
        var data:[AudioSampleType]!
        var asbd:AudioStreamBasicDescription!
    }
    
    //MARK:SourceAudioBufferData
    struct SourceAudioBufferData {
        var frameNum:UInt32 = 0
        var maxNumFrames:UInt32 = 0
        var soundBuffer = SoundBuffer()
    }
    
}