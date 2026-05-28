// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnrarKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "UnrarKit",
            targets: ["UnrarKit"]
        ),
    ],
    targets: [
        // unrar C++ 核心库
        .target(
            name: "unrar",
            path: "Libraries/unrar",
            exclude: [
                // 文档和非源文件
                "acknow.txt",
                "license.txt",
                "readme.txt",
                "makefile",
                "dll.def",
                "dll_nocrypt.def",
                "dll.rc",
                // 这些文件通过 #include 被其他文件隐式引入，不单独编译
                "arccmt.cpp",
                "blake2sp.cpp",
                "cmdfilter.cpp",
                "cmdmix.cpp",
                "coder.cpp",
                "crypt1.cpp",
                "crypt2.cpp",
                "crypt3.cpp",
                "crypt5.cpp",
                "hardlinks.cpp",
                "log.cpp",
                "model.cpp",
                "rarpch.cpp",
                "recvol3.cpp",
                "recvol5.cpp",
                "suballoc.cpp",
                "uicommon.cpp",
                "uiconsole.cpp",
                "uisilent.cpp",
                "ulinks.cpp",
                "unpack15.cpp",
                "unpack20.cpp",
                "unpack30.cpp",
                "unpack50.cpp",
                "unpack50frag.cpp",
                "unpack50mt.cpp",
                "unpackinline.cpp",
                "uowners.cpp",
                "win32acl.cpp",
                "win32lnk.cpp",
                "win32stm.cpp",
                "isnt.cpp",
                "threadmisc.cpp",
                "blake2s_sse.cpp",
            ],
            publicHeadersPath: ".",
            cxxSettings: [
                .define("SILENT"),
                .define("RARDLL"),
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),

        // UnrarKit Objective-C 封装层
        // Sources/UnrarKit/ 中的文件通过符号链接指向 Classes/ 目录
        // include/UnrarKit/ 中的头文件通过符号链接指向原始头文件
        // publicHeadersPath = "include" 且 include/ 下只有 UnrarKit/ 子目录
        // 这样 <UnrarKit/XXX.h> 能正确解析
        .target(
            name: "UnrarKit",
            dependencies: ["unrar"],
            path: "Sources/UnrarKit",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("../../Libraries/unrar"),
                .headerSearchPath("."),
                .headerSearchPath("include"),
            ],
            cxxSettings: [
                .define("SILENT"),
                .define("RARDLL"),
                .headerSearchPath("../../Libraries/unrar"),
                .headerSearchPath("."),
                .headerSearchPath("include"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
