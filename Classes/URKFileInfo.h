//
//  URKFileInfo.h
//  UnrarKit
//

#import <Foundation/Foundation.h>
#import <UnrarKit/UnrarKitMacros.h>

RarosHppIgnore
#import <UnrarKit/raros.hpp>
#pragma clang diagnostic pop

DllHppIgnore
#import <UnrarKit/dll.hpp>
#pragma clang diagnostic pop

/* See http://www.forensicswiki.org/wiki/RAR and
   http://www.rarlab.com/technote.htm#filehead for
   more information about the RAR File Header spec */

/**
 *  Defines the packing methods that can be used on a file in an archive
 */
typedef NS_ENUM(NSUInteger, URKCompressionMethod) {
    
    /**
     *  No compression is used
     */
    URKCompressionMethodStorage = 0x30,
    
    /**
     *  Fastest compression
     */
    URKCompressionMethodFastest = 0x31,
    
    /**
     *  Fast compression
     */
    URKCompressionMethodFast = 0x32,
    
    /**
     *  Normal compression
     */
    URKCompressionMethodNormal = 0x33,
    
    /**
     *  Good compression
     */
    URKCompressionMethodGood = 0x34,
    
    /**
     *  Best compression
     */
    URKCompressionMethodBest = 0x35,
};

/**
 *  Defines the various operating systems that can be used when archiving
 */
typedef NS_ENUM(NSUInteger, URKHostOS) {
    
    /**
     *  MS-DOS
     */
    URKHostOSMSDOS = 0,
    
    /**
     *  OS/2
     */
    URKHostOSOS2 = 1,
    
    /**
     *  Windows
     */
    URKHostOSWindows = 2,
    
    /**
     *  Unix
     */
    URKHostOSUnix = 3,
    
    /**
     *  Mac OS
     */
    URKHostOSMacOS = 4,
    
    /**
     *  BeOS
     */
    URKHostOSBeOS = 5,
};

/**
 *  Defines the hash types used for file integrity verification
 */
typedef NS_ENUM(NSUInteger, URKHashType) {
    
    /**
     *  No hash
     */
    URKHashTypeNone   = RAR_HASH_NONE,
    
    /**
     *  CRC32 checksum
     */
    URKHashTypeCRC32  = RAR_HASH_CRC32,
    
    /**
     *  BLAKE2sp hash (used in RAR5)
     */
    URKHashTypeBlake2 = RAR_HASH_BLAKE2,
};

/**
 *  Defines the redirect/symlink types for file entries
 */
typedef NS_ENUM(NSUInteger, URKRedirectType) {
    
    /**
     *  Not a redirect
     */
    URKRedirectTypeNone          = 0,
    
    /**
     *  Unix symbolic link
     */
    URKRedirectTypeUnixSymlink   = 1,
    
    /**
     *  Windows symbolic link
     */
    URKRedirectTypeWinSymlink    = 2,
    
    /**
     *  Windows junction
     */
    URKRedirectTypeWinJunction   = 3,
    
    /**
     *  Hard link
     */
    URKRedirectTypeHardLink      = 4,
    
    /**
     *  File copy (duplicate)
     */
    URKRedirectTypeFileCopy      = 5,
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  A wrapper around a RAR archive's file header, defining the various fields
 *  it contains
 */
@interface URKFileInfo : NSObject

/**
 *  The name of the file's archive
 */
@property (readonly, strong) NSString *archiveName;

/**
 *  The name of the file
 */
@property (readonly, strong) NSString *filename;

/**
 *  The last-modified timestamp of the file (from DOS date field).
 *  May be nil if the archive has no DOS timestamp (e.g. some RAR5 entries).
 *  For higher precision, use lastModifiedTime
 */
@property (readonly, strong, nullable) NSDate *timestamp;

/**
 *  High-precision last-modified time (from MtimeLow/MtimeHigh fields, RAR5).
 *  Falls back to timestamp (DOS date) if not available
 */
@property (readonly, strong, nullable) NSDate *lastModifiedTime;

/**
 *  High-precision creation time (from CtimeLow/CtimeHigh fields, RAR5).
 *  May be nil if not stored in the archive
 */
@property (readonly, strong, nullable) NSDate *creationTime;

/**
 *  High-precision last-access time (from AtimeLow/AtimeHigh fields, RAR5).
 *  May be nil if not stored in the archive
 */
@property (readonly, strong, nullable) NSDate *lastAccessTime;

/**
 *  The CRC checksum of the file
 */
@property (readonly, assign) NSUInteger CRC;

/**
 *  The hash type used for integrity verification (CRC32 or BLAKE2sp)
 */
@property (readonly, assign) URKHashType hashType;

/**
 *  The raw hash bytes (32 bytes). Interpretation depends on hashType.
 *  For CRC32, only the first 4 bytes are meaningful.
 *  For BLAKE2sp, all 32 bytes are used.
 */
@property (readonly, strong, nullable) NSData *fileHash;

/**
 *  Size of the uncompressed file
 */
@property (readonly, assign) long long uncompressedSize;

/**
 *  Size of the compressed file
 */
@property (readonly, assign) long long compressedSize;

/**
 *  The dictionary size used during compression (in bytes)
 */
@property (readonly, assign) NSUInteger dictionarySize;

/**
 *  YES if the file is encrypted with a password
 */
@property (readonly) BOOL isEncryptedWithPassword;

/**
 *  YES if the file is a directory
 */
@property (readonly) BOOL isDirectory;

/**
 *  YES if this file entry is continued from a previous volume
 */
@property (readonly) BOOL isSplitBefore;

/**
 *  YES if this file entry continues on the next volume
 */
@property (readonly) BOOL isSplitAfter;

/**
 *  YES if this file is part of a solid archive block
 */
@property (readonly) BOOL isSolid;

/**
 *  The redirect/symlink type of this entry (URKRedirectTypeNone if not a redirect)
 */
@property (readonly, assign) URKRedirectType redirectType;

/**
 *  The target path for redirect/symlink entries. Nil if not a redirect
 */
@property (readonly, strong, nullable) NSString *redirectName;

/**
 *  YES if this redirect entry points to a directory
 */
@property (readonly) BOOL redirectIsDirectory;

/**
 *  The type of compression
 */
@property (readonly, assign) URKCompressionMethod compressionMethod;

/**
 *  The OS of the file
 */
@property (readonly, assign) URKHostOS hostOS;

/**
 *  Returns a URKFileInfo instance for the given extended header data
 *
 *  @param fileHeader The header data for a RAR file
 *
 *  @return an instance of URKFileInfo
 */
+ (instancetype) fileInfo:(struct RARHeaderDataEx * _Nonnull)fileHeader;

@end

NS_ASSUME_NONNULL_END
