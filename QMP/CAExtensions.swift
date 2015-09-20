//
//  AudioStreamBasicDescriptionExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/24/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import AudioToolbox

typealias AudioSampleType = Int16
typealias AudioUnitSampleType = Int32

let kAudioFormatFlagsCanonical = AudioFormatFlags(kAudioFormatFlagIsSignedInteger) | AudioFormatFlags(kAudioFormatFlagsNativeEndian) | AudioFormatFlags(kAudioFormatFlagIsPacked)
let kAudioFormatFlagsAudioUnitCanonical = AudioFormatFlags(kAudioFormatFlagIsSignedInteger) | AudioFormatFlags(kAudioFormatFlagsNativeEndian) | AudioFormatFlags(kAudioFormatFlagIsPacked) | (AudioFormatFlags(kAudioUnitSampleFractionBits) << AudioFormatFlags(kLinearPCMFormatFlagsSampleFractionShift))


extension AudioStreamBasicDescription {
    
    init() {
        mSampleRate = 0
        mFormatID = 0
        mFormatFlags = 0
        mBytesPerPacket = 0
        mFramesPerPacket = 0
        mBytesPerFrame = 0
        mChannelsPerFrame = 0
        mBitsPerChannel = 0
        mReserved = 0
    }
    
    mutating func setCanonical(nChannels:UInt32, interleaved:Bool, forAudioUnit:Bool) {
        mFormatID = AudioFormatID(kAudioFormatLinearPCM)
        let sampleSize = forAudioUnit ? sizeOf32(AudioUnitSampleType) : sizeOf32(AudioSampleType)
        mFormatFlags = forAudioUnit ? kAudioFormatFlagsAudioUnitCanonical : kAudioFormatFlagsCanonical
        mBitsPerChannel = 8 * sampleSize
        mChannelsPerFrame = nChannels
        mFramesPerPacket = 1
        if(interleaved) {
            mBytesPerFrame = nChannels * sampleSize
        } else {
            mBytesPerFrame = sampleSize
            mFormatFlags |= AudioFormatFlags(kAudioFormatFlagIsNonInterleaved)
        }
        mBytesPerPacket = mBytesPerFrame
    }
    
}

extension AudioComponentDescription {
    init(inType:Int, inSubType:Int, inManufacturer:Int) {
        componentType = OSType(inType)
        componentSubType = OSType(inSubType)
        componentManufacturer = OSType(inManufacturer)
        componentFlags = 0
        componentFlagsMask = 0
    }
}

extension AudioBufferList {

}

extension AudioStreamBasicDescription {
    
}

func sizeOf32<T>(type:T) -> UInt32 {
    return UInt32(sizeof(type.dynamicType))
}

func sizeOf32<T>(type:T.Type) -> UInt32 {
    return UInt32(sizeof(type))
}


struct CoreAudioHelper {
    static func checkError(error:OSStatus) -> String{
        if error == 0 {return ""}
        
        switch(error) {
            // AudioToolbox
        case kAUGraphErr_NodeNotFound:
            return "Error:kAUGraphErr_NodeNotFound \n"
            
        case kAUGraphErr_OutputNodeErr:
            return  "Error:kAUGraphErr_OutputNodeErr \n"
            
        case kAUGraphErr_InvalidConnection:
            return "Error:kAUGraphErr_InvalidConnection \n"
            
        case kAUGraphErr_CannotDoInCurrentContext:
            return  "Error:kAUGraphErr_CannotDoInCurrentContext \n"
            
        case kAUGraphErr_InvalidAudioUnit:
            return  "Error:kAUGraphErr_InvalidAudioUnit \n"
            
        case kAudioToolboxErr_InvalidSequenceType :
            return  " kAudioToolboxErr_InvalidSequenceType "
            
        case kAudioToolboxErr_TrackIndexError :
            return  " kAudioToolboxErr_TrackIndexError "
            
        case kAudioToolboxErr_TrackNotFound :
            return  " kAudioToolboxErr_TrackNotFound "
            
        case kAudioToolboxErr_EndOfTrack :
            return  " kAudioToolboxErr_EndOfTrack "
            
        case kAudioToolboxErr_StartOfTrack :
            return  " kAudioToolboxErr_StartOfTrack "
            
        case kAudioToolboxErr_IllegalTrackDestination	:
            return  " kAudioToolboxErr_IllegalTrackDestination"
            
        case kAudioToolboxErr_NoSequence 		:
            return  " kAudioToolboxErr_NoSequence "
            
        case kAudioToolboxErr_InvalidEventType		:
            return  " kAudioToolboxErr_InvalidEventType"
            
        case kAudioToolboxErr_InvalidPlayerState	:
            return  " kAudioToolboxErr_InvalidPlayerState"
            
        case kAudioUnitErr_InvalidProperty		:
            return  " kAudioUnitErr_InvalidProperty"
            
        case kAudioUnitErr_InvalidParameter		:
            return  " kAudioUnitErr_InvalidParameter"
            
        case kAudioUnitErr_InvalidElement		:
            return  " kAudioUnitErr_InvalidElement"
            
        case kAudioUnitErr_NoConnection			:
            return  " kAudioUnitErr_NoConnection"
            
        case kAudioUnitErr_FailedInitialization		:
            return  " kAudioUnitErr_FailedInitialization"
            
        case kAudioUnitErr_TooManyFramesToProcess	:
            return  " kAudioUnitErr_TooManyFramesToProcess"
            
        case kAudioUnitErr_InvalidFile			:
            return  " kAudioUnitErr_InvalidFile"
            
        case kAudioUnitErr_FormatNotSupported		:
            return  " kAudioUnitErr_FormatNotSupported"
            
        case kAudioUnitErr_Uninitialized		:
            return  " kAudioUnitErr_Uninitialized"
            
        case kAudioUnitErr_InvalidScope			:
            return  " kAudioUnitErr_InvalidScope"
            
        case kAudioUnitErr_PropertyNotWritable		:
            return  " kAudioUnitErr_PropertyNotWritable"
            
        case kAudioUnitErr_InvalidPropertyValue		:
            return  " kAudioUnitErr_InvalidPropertyValue"
            
        case kAudioUnitErr_PropertyNotInUse		:
            return  " kAudioUnitErr_PropertyNotInUse"
            
        case kAudioUnitErr_Initialized			:
            return  " kAudioUnitErr_Initialized"
            
        case kAudioUnitErr_InvalidOfflineRender		:
            return  " kAudioUnitErr_InvalidOfflineRender"
            
        case kAudioUnitErr_Unauthorized			:
            return  " kAudioUnitErr_Unauthorized"
        case kExtAudioFileError_CodecUnavailableInputConsumed:
            return "kExtAudioFileError_CodecUnavailableInputConsumed"
        case kExtAudioFileError_CodecUnavailableInputNotConsumed:
            return "kExtAudioFileError_CodecUnavailableInputNotConsumed"
        case kExtAudioFileError_InvalidProperty:
            return "kExtAudioFileError_InvalidProperty"
        case kExtAudioFileError_InvalidPropertySize:
            return "kExtAudioFileError_InvalidPropertySize"
        case kExtAudioFileError_NonPCMClientFormat:
            return "kExtAudioFileError_NonPCMClientFormat"
        case kExtAudioFileError_InvalidChannelMap:
            return "kExtAudioFileError_InvalidChannelMap"
        case kExtAudioFileError_InvalidOperationOrder:
            return "kExtAudioFileError_InvalidOperationOrder"
        case kExtAudioFileError_InvalidDataFormat:
            return "kExtAudioFileError_InvalidDataFormat"
        case kExtAudioFileError_MaxPacketSizeUnknown:
            return "kExtAudioFileError_MaxPacketSizeUnknown"
        case kExtAudioFileError_InvalidSeek:
            return "kExtAudioFileError_InvalidSeek"
        case kExtAudioFileError_AsyncWriteTooLarge:
            return "kExtAudioFileError_AsyncWriteTooLarge"
        case kExtAudioFileError_AsyncWriteBufferOverflow:
            return "kExtAudioFileError_AsyncWriteBufferOverflow"
        case kAudioFileUnspecifiedError: return "kAudioFileUnspecifiedError"
        case kAudioFileUnsupportedFileTypeError: return "kAudioFileUnsupportedFileTypeError"
        case kAudioFileUnsupportedDataFormatError: return "kAudioFileUnsupportedDataFormatError"
        case kAudioFileUnsupportedPropertyError: return "kAudioFileUnsupportedPropertyError"
        case kAudioFileBadPropertySizeError: return "kAudioFileBadPropertySizeError"
        case kAudioFilePermissionsError: return "kAudioFilePermissionsError"
        case kAudioFileNotOptimizedError: return "kAudioFileNotOptimizedError"
        case kAudioFileInvalidChunkError: return "kAudioFileInvalidChunkError"
        case kAudioFileDoesNotAllow64BitDataSizeError: return "kAudioFileDoesNotAllow64BitDataSizeError"
        case kAudioFileInvalidPacketOffsetError: return "kAudioFileInvalidPacketOffsetError"
        case kAudioFileInvalidFileError: return "kAudioFileInvalidFileError"
        case kAudioFileOperationNotSupportedError: return "kAudioFileOperationNotSupportedError"
        case kAudioFileNotOpenError: return "kAudioFileNotOpenError"
        case kAudioFileEndOfFileError: return "kAudioFileEndOfFileError"
        case kAudioFilePositionError: return "kAudioFilePositionError"
        case kAudioFileFileNotFoundError: return "kAudioFileFileNotFoundError"
        default:
            return "huh? \(Int(error)), \(error)"
        }
    }
}