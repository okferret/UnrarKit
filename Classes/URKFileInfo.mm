//
//  URKFileInfo.mm
//  UnrarKit
//

#import "URKFileInfo.h"
#import "UnrarKitMacros.h"

#import "NSString+UnrarKit.h"

// Windows FILETIME epoch: January 1, 1601
// Unix epoch: January 1, 1970
// Difference in 100-nanosecond intervals
static const uint64_t kWindowsFileTimeEpochDelta = 116444736000000000ULL;
// 100-nanosecond intervals per second
static const uint64_t kWindowsFileTimeIntervalsPerSecond = 10000000ULL;

@implementation URKFileInfo



#pragma mark - Initialization


+ (instancetype) fileInfo:(struct RARHeaderDataEx *)fileHeader {
    return [[URKFileInfo alloc] initWithFileHeader:fileHeader];
}

- (instancetype)initWithFileHeader:(struct RARHeaderDataEx *)fileHeader
{
    URKCreateActivity("Init URKFileInfo");

    if ((self = [super init])) {
        URKLogDebug("Setting file info fields");
        
        _filename = [NSString stringWithUnichars:fileHeader->FileNameW];
        _archiveName = [NSString stringWithUnichars:fileHeader->ArcNameW];
        _uncompressedSize = (long long) fileHeader->UnpSizeHigh << 32 | fileHeader->UnpSize;
        _compressedSize = (long long) fileHeader->PackSizeHigh << 32 | fileHeader->PackSize;
        _compressionMethod = (URKCompressionMethod)fileHeader->Method;
        _hostOS = (URKHostOS)fileHeader->HostOS;
        _CRC = fileHeader->FileCRC;

        // Dictionary size
        _dictionarySize = fileHeader->DictSize;

        // Hash type and raw hash data
        _hashType = (URKHashType)fileHeader->HashType;
        if (fileHeader->HashType != RAR_HASH_NONE) {
            _fileHash = [NSData dataWithBytes:fileHeader->Hash length:sizeof(fileHeader->Hash)];
        } else {
            _fileHash = nil;
        }

        // File flags
        _isEncryptedWithPassword = (fileHeader->Flags & RHDF_ENCRYPTED) != 0;
        _isDirectory = (fileHeader->Flags & RHDF_DIRECTORY) ? YES : NO;
        _isSplitBefore = (fileHeader->Flags & RHDF_SPLITBEFORE) != 0;
        _isSplitAfter  = (fileHeader->Flags & RHDF_SPLITAFTER)  != 0;
        _isSolid       = (fileHeader->Flags & RHDF_SOLID)       != 0;

        // Redirect / symlink info
        _redirectType = (URKRedirectType)fileHeader->RedirType;
        _redirectIsDirectory = fileHeader->DirTarget != 0;
        if (fileHeader->RedirType != 0 && fileHeader->RedirName != NULL) {
            _redirectName = [NSString stringWithUnichars:fileHeader->RedirName];
        } else {
            _redirectName = nil;
        }

        // Timestamps
        // DOS modification time (always present when non-zero)
        _timestamp = [self parseDOSDate:fileHeader->FileTime];

        // High-precision modification time (MtimeLow/MtimeHigh, Windows FILETIME format)
        _lastModifiedTime = [self parseWindowsFileTimeLow:fileHeader->MtimeLow
                                                     high:fileHeader->MtimeHigh
                                              fallbackDOS:fileHeader->FileTime];

        // High-precision creation time
        _creationTime = [self parseWindowsFileTimeLow:fileHeader->CtimeLow
                                                 high:fileHeader->CtimeHigh
                                          fallbackDOS:0];

        // High-precision last-access time
        _lastAccessTime = [self parseWindowsFileTimeLow:fileHeader->AtimeLow
                                                   high:fileHeader->AtimeHigh
                                            fallbackDOS:0];
    }

    return self;
}



#pragma mark - Private Methods


- (NSDate *)parseDOSDate:(NSUInteger)dosTime
{
    URKCreateActivity("-parseDOSDate:");

    if (dosTime == 0) {
        URKLogDebug("DOS Time == 0");
        return nil;
    }
    
    // MSDOS Date Format Parsing specified at this URL:
    // http://www.cocoanetics.com/2012/02/decompressing-files-into-memory/
    
    int year = ((dosTime>>25) & 127) + 1980; // 7 bits
    int month = (dosTime>>21) & 15;          // 4 bits
    int day = (dosTime>>16) & 31;            // 5 bits
    int hour = (dosTime>>11) & 31;           // 5 bits
    int minute = (dosTime>>5) & 63;          // 6 bits
    int second = (dosTime & 31) * 2;         // 5 bits
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = second;
    
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

/**
 *  Parse a Windows FILETIME value (stored as two 32-bit halves) into an NSDate.
 *  Windows FILETIME counts 100-nanosecond intervals since January 1, 1601 UTC.
 *
 *  @param low         Low 32 bits of the FILETIME value
 *  @param high        High 32 bits of the FILETIME value
 *  @param fallbackDOS DOS date/time to use if the FILETIME is zero (pass 0 to return nil)
 *
 *  @return An NSDate, or nil if both the FILETIME and fallback are zero
 */
- (nullable NSDate *)parseWindowsFileTimeLow:(unsigned int)low
                                        high:(unsigned int)high
                                 fallbackDOS:(NSUInteger)fallbackDOS
{
    URKCreateActivity("-parseWindowsFileTimeLow:high:fallbackDOS:");

    uint64_t fileTime = ((uint64_t)high << 32) | (uint64_t)low;

    if (fileTime == 0) {
        URKLogDebug("Windows FILETIME == 0, using DOS fallback");
        return [self parseDOSDate:fallbackDOS];
    }

    // Convert from Windows FILETIME (100-ns intervals since 1601-01-01)
    // to Unix timestamp (seconds since 1970-01-01)
    if (fileTime < kWindowsFileTimeEpochDelta) {
        URKLogDebug("Windows FILETIME predates Unix epoch, using DOS fallback");
        return [self parseDOSDate:fallbackDOS];
    }

    uint64_t unixIntervals = fileTime - kWindowsFileTimeEpochDelta;
    NSTimeInterval unixSeconds = (NSTimeInterval)unixIntervals / (NSTimeInterval)kWindowsFileTimeIntervalsPerSecond;

    URKLogDebug("Parsed Windows FILETIME %llu -> Unix timestamp %.6f", (unsigned long long)fileTime, unixSeconds);
    return [NSDate dateWithTimeIntervalSince1970:unixSeconds];
}

@end
