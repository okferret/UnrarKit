# UnrarKit

[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](#平台支持)
[![License](https://img.shields.io/badge/license-unRAR-blue.svg)](Libraries/unrar/license.txt)

## 简介

UnrarKit 是一个面向 macOS / iOS / tvOS / watchOS 平台的 Objective-C 框架，用于对 RAR 格式压缩文件进行**只读**操作。底层基于官方 [UnRAR 库](http://www.rarlab.com/rar/unrarsrc-5.8.1.tar.gz) 5.8.1 版本构建，同时支持 RAR 4.x 与 RAR 5 两种格式。

项目包含主工程（含单元测试）和一个基础 iOS 示例工程，演示了如何使用该库。打开 [`UnrarKit.xcworkspace`](UnrarKit.xcworkspace) 即可查看所有内容。

欢迎提交 Pull Request 或[创建 Issue](https://github.com/abbeycode/UnrarKit/issues)。

---

## 平台支持

| 平台    | 最低版本 |
|---------|---------|
| macOS   | 10.15+  |
| iOS     | 13.0+   |
| tvOS    | 13.0+   |
| watchOS | 6.0+    |

---

## 安装

### Swift Package Manager（推荐）

在 [`Package.swift`](Package.swift) 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/abbeycode/UnrarKit.git", from: "2.0.0")
]
```

或在 Xcode 中通过 **File → Add Packages…** 输入仓库地址进行集成。

---

## 快速开始

### 初始化归档对象

```objc
NSError *archiveError = nil;

// 通过文件路径初始化
URKArchive *archive = [[URKArchive alloc] initWithPath:@"An Archive.rar" error:&archiveError];

// 或通过 URL 初始化
URKArchive *archive = [[URKArchive alloc] initWithURL:fileURL error:&archiveError];
```

### 检测文件是否为 RAR 格式

```objc
BOOL isRAR = [URKArchive pathIsARAR:@"/path/to/file.rar"];
BOOL isRAR = [URKArchive urlIsARAR:fileURL];
```

---

## 归档元信息

[`URKArchive`](Sources/UnrarKit/URKArchive.h) 提供了一组只读属性，用于获取归档自身的元信息：

| 属性                    | 类型             | 说明                                       |
|-------------------------|------------------|--------------------------------------------|
| `fileURL`               | `NSURL *`        | 归档文件 URL                               |
| `filename`              | `NSString *`     | 归档文件名                                 |
| `uncompressedSize`      | `NSNumber *`     | 所有文件解压后的总大小（字节）             |
| `compressedSize`        | `NSNumber *`     | 归档压缩后的总大小（字节）                 |
| `hasMultipleVolumes`    | `BOOL`           | 是否为多卷归档的一部分                     |
| `archiveComment`        | `NSString *`     | 归档注释（仅 RAR 1.5–4.x 支持）            |
| `isSolidArchive`        | `BOOL`           | 是否为 solid（连续）归档                   |
| `hasEncryptedHeaders`   | `BOOL`           | 归档头是否加密                             |
| `hasRecoveryRecord`     | `BOOL`           | 是否包含恢复记录                           |
| `isLocked`              | `BOOL`           | 归档是否被锁定（禁止修改）                 |

---

## 主要功能

### 列出归档中的文件名

```objc
NSError *error = nil;
NSArray<NSString *> *filesInArchive = [archive listFilenames:&error];
for (NSString *name in filesInArchive) {
    NSLog(@"归档文件: %@", name);
}
```

### 列出归档中的文件详情

```objc
NSError *error = nil;
NSArray<URKFileInfo *> *fileInfosInArchive = [archive listFileInfo:&error];
for (URKFileInfo *info in fileInfosInArchive) {
    NSLog(@"归档名: %@ | 文件名: %@ | 大小: %lld",
          info.archiveName, info.filename, info.uncompressedSize);
}
```

### 遍历文件信息（迭代器方式）

```objc
NSError *error = nil;
[archive iterateFileInfo:^(URKFileInfo *fileInfo, BOOL *stop) {
    NSLog(@"文件: %@, 压缩方式: %lu", fileInfo.filename, (unsigned long)fileInfo.compressionMethod);
    // 设置 *stop = YES 可提前终止遍历
} error:&error];
```

### 解压所有文件到目录

```objc
NSError *error = nil;
BOOL success = [archive extractFilesTo:@"some/directory"
                              overwrite:NO
                                  error:&error];
```

### 解压单个文件到内存

```objc
NSError *error = nil;
NSData *extractedData = [archive extractDataFromFile:@"a file in the archive.jpg"
                                               error:&error];
```

### 流式解压（适合大文件）

对于大文件，可以分块处理，避免一次性占用大量内存：

```objc
NSError *error = nil;
BOOL success = [archive extractBufferedDataFromFile:@"a file in the archive.jpg"
                                              error:&error
                                             action:
                ^(NSData *dataChunk, CGFloat percentDecompressed) {
                    NSLog(@"已解压: %.1f%%", percentDecompressed * 100);
                    // 处理每个数据块
                }];
```

### 对归档中每个文件执行操作

```objc
NSError *error = nil;

// 仅操作文件信息（按字母顺序）
[archive performOnFilesInArchive:^(URKFileInfo *fileInfo, BOOL *stop) {
    NSLog(@"处理文件: %@", fileInfo.filename);
} error:&error];

// 操作文件信息及其数据
[archive performOnDataInArchive:^(URKFileInfo *fileInfo, NSData *fileData, BOOL *stop) {
    NSLog(@"文件: %@, 数据大小: %lu", fileInfo.filename, (unsigned long)fileData.length);
} error:&error];
```

### 列出多卷归档的所有卷

```objc
NSError *error = nil;
NSArray<NSURL *> *volumes = [archive listVolumeURLs:&error];
```

---

## 密码保护归档

### 初始化时指定密码

```objc
NSError *error = nil;
URKArchive *archive = [[URKArchive alloc] initWithPath:@"encrypted.rar"
                                            password:@"myPassword"
                                                  error:&error];
```

### 动态设置密码

```objc
NSError *error = nil;
NSArray<URKFileInfo *> *fileInfos = [archive listFileInfo:&error];

if ([archive isPasswordProtected]) {
    NSString *password = // 提示用户输入密码
    archive.password = password;
}

// 现在可以解压文件
```

### 验证密码

```objc
BOOL isValid = [archive validatePassword];
```

---

## 数据完整性校验

```objc
// 校验整个归档
BOOL isValid = [archive checkDataIntegrity];

// 校验单个文件
BOOL isValid = [archive checkDataIntegrityOfFile:@"file.txt"];

// 校验时允许用户决定是否忽略 CRC 不匹配
BOOL isValid = [archive checkDataIntegrityIgnoringCRCMismatches:^BOOL {
    // 在主线程上调用，可弹出提示框让用户决定
    return YES; // 返回 YES 则忽略 CRC 不匹配
}];
```

> 也可以直接将 `archive.ignoreCRCMismatches = YES` 来跳过 CRC 校验，但请注意这可能存在安全风险。

---

## 进度报告

以下方法支持 `NSProgress` 与 `NSProgressReporting`：

- [`URKArchive.extractFilesTo:overwrite:error:`](Sources/UnrarKit/URKArchive.h:374)
- [`URKArchive.extractData:error:`](Sources/UnrarKit/URKArchive.h:406)
- [`URKArchive.extractDataFromFile:error:`](Sources/UnrarKit/URKArchive.h:437)
- [`URKArchive.performOnFilesInArchive:error:`](Sources/UnrarKit/URKArchive.h:470)
- [`URKArchive.performOnDataInArchive:error:`](Sources/UnrarKit/URKArchive.h:488)
- [`URKArchive.extractBufferedDataFromFile:error:action:`](Sources/UnrarKit/URKArchive.h:504)

`extractFilesTo:overwrite:error:` 还会通过 `NSProgress` 的 `userInfo` 暴露当前正在解压的文件，键名为 `URKProgressInfoKeyFileInfoExtracting`，值为 [`URKFileInfo`](Sources/UnrarKit/URKFileInfo.h:156)。

### 使用隐式 NSProgress 层级

```objc
static void *ExtractDataContext = &ExtractDataContext;

URKArchive *archive = [[URKArchive alloc] initWithURL:aFileURL error:nil];

NSProgress *extractDataProgress = [NSProgress progressWithTotalUnitCount:1];
[extractDataProgress becomeCurrentWithPendingUnitCount:1];

NSString *observedSelector = NSStringFromSelector(@selector(fractionCompleted));
[extractDataProgress addObserver:self
                      forKeyPath:observedSelector
                         options:NSKeyValueObservingOptionInitial
                         context:ExtractDataContext];

NSError *extractError = nil;
NSData *data = [archive extractDataFromFile:firstFile error:&extractError];

[extractDataProgress resignCurrent];
[extractDataProgress removeObserver:self forKeyPath:observedSelector];
```

### 使用显式 NSProgress 实例

```objc
static void *ExtractFilesContext = &ExtractFilesContext;

URKArchive *archive = [[URKArchive alloc] initWithURL:aFileURL error:nil];

NSProgress *extractFilesProgress = [NSProgress progressWithTotalUnitCount:1];
archive.progress = extractFilesProgress;

NSString *observedSelector = NSStringFromSelector(@selector(localizedDescription));
[extractFilesProgress addObserver:self
                       forKeyPath:observedSelector
                          options:NSKeyValueObservingOptionInitial
                          context:ExtractFilesContext];

NSError *extractError = nil;
BOOL success = [archive extractFilesTo:extractURL.path
                             overwrite:NO
                                 error:&extractError];

[extractFilesProgress removeObserver:self forKeyPath:observedSelector];
```

### 取消操作

通过上述任一方式，调用 `[progress cancel]` 即可停止当前操作。操作将失败并返回 `nil` 或 `NO`，同时返回错误码 `URKErrorCodeUserCancelled`。

---

## URKFileInfo 属性说明

[`URKFileInfo`](Sources/UnrarKit/URKFileInfo.h) 是对 RAR 归档文件头的封装，提供以下只读属性：

### 基本信息

| 属性                  | 类型                    | 说明                                  |
|-----------------------|-------------------------|---------------------------------------|
| `archiveName`         | `NSString *`            | 所属归档文件名                        |
| `filename`            | `NSString *`            | 文件名（含归档内路径）                |
| `uncompressedSize`    | `long long`             | 解压后大小（字节）                    |
| `compressedSize`      | `long long`             | 压缩后大小（字节）                    |
| `dictionarySize`      | `NSUInteger`            | 压缩时使用的字典大小（字节）          |
| `compressionMethod`   | `URKCompressionMethod`  | 压缩方式                              |
| `hostOS`              | `URKHostOS`             | 创建归档的操作系统                    |
| `isDirectory`         | `BOOL`                  | 是否为目录                            |

### 时间戳（高精度）

| 属性                  | 类型                    | 说明                                  |
|-----------------------|-------------------------|---------------------------------------|
| `timestamp`           | `NSDate *`              | DOS 格式最后修改时间（精度较低）      |
| `lastModifiedTime`    | `NSDate *`              | 高精度最后修改时间（RAR5）            |
| `creationTime`        | `NSDate *`              | 高精度创建时间（RAR5）                |
| `lastAccessTime`      | `NSDate *`              | 高精度最后访问时间（RAR5）            |

### 数据完整性

| 属性                  | 类型                    | 说明                                       |
|-----------------------|-------------------------|--------------------------------------------|
| `CRC`                 | `NSUInteger`            | CRC32 校验值                               |
| `hashType`            | `URKHashType`           | 校验类型：`None` / `CRC32` / `Blake2`      |
| `fileHash`            | `NSData *`              | 原始哈希字节（最大 32 字节）；CRC32 仅前 4 字节有效，BLAKE2sp 全部有效 |

### 加密 / 多卷 / Solid

| 属性                          | 类型     | 说明                                  |
|-------------------------------|----------|---------------------------------------|
| `isEncryptedWithPassword`  | `BOOL`   | 是否使用密码加密                      |
| `isSplitBefore`               | `BOOL`   | 是否从上一卷续写而来                  |
| `isSplitAfter`                | `BOOL`   | 是否在下一卷继续                      |
| `isSolid`                     | `BOOL`   | 是否属于某个 solid 块                 |

### 重定向 / 符号链接

| 属性                    | 类型               | 说明                                                                 |
|-------------------------|--------------------|----------------------------------------------------------------------|
| `redirectType`          | `URKRedirectType`  | 重定向类型：`None` / `UnixSymlink` / `WinSymlink` / `WinJunction` / `HardLink` / `FileCopy` |
| `redirectName`          | `NSString *`       | 重定向的目标路径                                                     |
| `redirectIsDirectory`   | `BOOL`             | 重定向目标是否为目录                                                 |

---

## 错误码说明

定义于 [`URKErrorCode`](Sources/UnrarKit/URKArchive.h:25)：

| 错误码                              | 说明                         |
|-------------------------------------|------------------------------|
| `URKErrorCodeEndOfArchive`          | 已读取到归档末尾             |
| `URKErrorCodeNoMemory`              | 内存不足                     |
| `URKErrorCodeBadData`               | 数据 CRC 校验失败            |
| `URKErrorCodeBadArchive`            | 无效的 RAR 归档              |
| `URKErrorCodeUnknownFormat`         | 不支持的 RAR 格式或版本      |
| `URKErrorCodeOpen`                  | 无法打开文件                 |
| `URKErrorCodeCreate`                | 无法创建目标目录             |
| `URKErrorCodeClose`                 | 无法关闭归档                 |
| `URKErrorCodeRead`                  | 读取归档失败                 |
| `URKErrorCodeWrite`                 | 写入文件失败                 |
| `URKErrorCodeSmall`                 | 注释长度超过缓冲区大小       |
| `URKErrorCodeUnknown`               | 未明确分类的错误             |
| `URKErrorCodeMissingPassword`    | 加密归档未提供密码           |
| `URKErrorCodeBadPassword`        | 提供的密码错误               |
| `URKErrorCodeArchiveNotFound`       | 归档文件未找到               |
| `URKErrorCodeUserCancelled`         | 用户取消了操作               |
| `URKErrorCodeStringConversion`      | 字符串转换为 UTF-8 失败      |

---

## 日志

UnrarKit 使用 Apple 的[统一日志框架](https://developer.apple.com/documentation/os/logging)进行日志记录和活动追踪，可在 Console.app 中按 subsystem `com.abbey-code.UnrarKit` 过滤查看。

### 调整日志级别

如需降低 UnrarKit 的日志详细程度，可在终端运行：

```bash
sudo log config --mode "level:default" --subsystem com.abbey-code.UnrarKit
```

可用级别（详细程度递增）：`default` → `info` → `debug`，默认为 `debug`。

### 日志规范

| 级别      | 用途                                                                 |
|-----------|----------------------------------------------------------------------|
| `default` | 无消息（允许消费者完全关闭诊断日志）                                 |
| `info`    | 主要操作（初始化、删除文件）、公共方法调用及参数、非典型条件         |
| `debug`   | 私有方法、变量值、循环迭代详情                                       |
| `error`   | 每个 `NSError` 生成时记录，包含错误码枚举名称                        |
| `fault`   | Cocoa 框架方法返回错误时使用                                         |

---

## 在 Xcode 中打开

使用 [`UnrarKit.xcworkspace`](UnrarKit.xcworkspace) 文件打开项目，该工作区包含所有子项目。

### 示例应用

仓库中包含名为 **UnrarExample** 的 iOS 示例项目，已验证可在模拟器中运行。如需在真机运行，请配置 Team 信息。

---

## 发布新版本

新的标签构建（任意分支）满足以下条件时将自动发布：

1. 所有构建和测试通过
2. 标签符合版本号格式（`#.#.#(-beta#)`，如 **2.9** 或 **2.9-beta5**）

### 发布步骤

1. 将发布说明添加到 [`CHANGELOG.md`](CHANGELOG.md) 并提交
2. 运行版本设置脚本：

    ```bash
    ./Scripts/set-version.sh <版本号>
    ```

    该脚本将：
    - 更新 [`Resources/UnrarKit-Info.plist`](Resources/UnrarKit-Info.plist) 中的版本号并提交
    - 创建包含发布说明的带注释标签

3. 推送代码和标签：

    ```bash
    git push --follow-tags
    ```

    > 可通过以下命令设置默认推送标签：
    > ```bash
    > git config --global push.followTags true
    > ```

---

## 贡献者

- Dov Frankel (dov@abbey-code.com)
- Rogerio Pereira Araujo (rogerio.araujo@gmail.com)
- Vicent Scott (vkan388@gmail.com)

---

## 许可证

UnrarKit 基于 unRAR 库构建，使用须遵守 [unRAR 许可证](Libraries/unrar/license.txt)的相关条款（禁止将 unRAR 源代码用于重新创建 RAR 压缩算法）。
