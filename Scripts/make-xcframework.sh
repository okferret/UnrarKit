#!/bin/bash
#
# make-xcframework.sh
#
# 使用 xcodebuild 为多个平台构建 UnrarKit.xcframework
# 支持：macOS、iOS、iOS Simulator、tvOS、tvOS Simulator、watchOS、watchOS Simulator
#
# 用法：
#   ./Scripts/make-xcframework.sh
#   ./Scripts/make-xcframework.sh --output /path/to/output
#   ./Scripts/make-xcframework.sh --configuration Release
#

set -euo pipefail

# ── 默认参数 ──────────────────────────────────────────────────────────────────
SCHEME="UnrarKit"
PROJECT="UnrarKit.xcodeproj"
CONFIGURATION="Release"
OUTPUT_DIR="$(pwd)/build/xcframework"
ARCHIVES_DIR="$(pwd)/build/archives"
FRAMEWORK_NAME="UnrarKit"

# ── 解析命令行参数 ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --help|-h)
            echo "用法: $0 [--output <目录>] [--configuration <Debug|Release>]"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

XCFRAMEWORK_PATH="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

echo "=================================================="
echo "  构建 ${FRAMEWORK_NAME}.xcframework"
echo "  配置: ${CONFIGURATION}"
echo "  输出: ${XCFRAMEWORK_PATH}"
echo "=================================================="

# ── 清理旧产物 ─────────────────────────────────────────────────────────────────
rm -rf "${ARCHIVES_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${ARCHIVES_DIR}"
mkdir -p "${OUTPUT_DIR}"

# ── 构建各平台 Archive ─────────────────────────────────────────────────────────

build_archive() {
    local PLATFORM="$1"
    local SDK="$2"
    local DESTINATION="$3"
    local ARCHIVE_PATH="${ARCHIVES_DIR}/${PLATFORM}.xcarchive"

    echo ""
    echo "▶ 构建 ${PLATFORM} (SDK: ${SDK})..."

    xcodebuild archive \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -sdk "${SDK}" \
        -destination "${DESTINATION}" \
        -archivePath "${ARCHIVE_PATH}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        ONLY_ACTIVE_ARCH=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        2>&1 | grep -E "^(Build|error:|warning:|note:|CompileC|Ld |Archive)" || true

    if [ ! -d "${ARCHIVE_PATH}" ]; then
        echo "  ✗ 构建失败: ${ARCHIVE_PATH} 不存在"
        exit 1
    fi

    echo "  ✓ ${PLATFORM} archive: ${ARCHIVE_PATH}"
}

# macOS (arm64 + x86_64)
build_archive \
    "macos" \
    "macosx" \
    "generic/platform=macOS"

# iOS (arm64 设备)
build_archive \
    "ios" \
    "iphoneos" \
    "generic/platform=iOS"

# iOS Simulator (arm64 + x86_64)
build_archive \
    "ios-simulator" \
    "iphonesimulator" \
    "generic/platform=iOS Simulator"

# tvOS (arm64 设备)
build_archive \
    "tvos" \
    "appletvos" \
    "generic/platform=tvOS"

# tvOS Simulator
build_archive \
    "tvos-simulator" \
    "appletvsimulator" \
    "generic/platform=tvOS Simulator"

# watchOS (arm64_32 设备)
build_archive \
    "watchos" \
    "watchos" \
    "generic/platform=watchOS"

# watchOS Simulator
build_archive \
    "watchos-simulator" \
    "watchsimulator" \
    "generic/platform=watchOS Simulator"

# ── 合并为 xcframework ─────────────────────────────────────────────────────────

echo ""
echo "▶ 合并为 ${FRAMEWORK_NAME}.xcframework..."

FRAMEWORK_ARGS=()
for ARCHIVE_PATH in "${ARCHIVES_DIR}"/*.xcarchive; do
    FW="${ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    if [ -d "${FW}" ]; then
        FRAMEWORK_ARGS+=("-framework" "${FW}")
    else
        echo "  ⚠ 未找到 framework: ${FW}"
    fi
done

if [ ${#FRAMEWORK_ARGS[@]} -eq 0 ]; then
    echo "错误：没有找到任何 framework，请检查构建日志"
    exit 1
fi

xcodebuild -create-xcframework \
    "${FRAMEWORK_ARGS[@]}" \
    -output "${XCFRAMEWORK_PATH}"

echo ""
echo "=================================================="
echo "  ✅ 构建完成！"
echo "  ${XCFRAMEWORK_PATH}"
echo "=================================================="

# ── 可选：打包为 zip ───────────────────────────────────────────────────────────
ZIP_PATH="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
echo ""
echo "▶ 打包为 zip: ${ZIP_PATH}"
cd "${OUTPUT_DIR}"
zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
echo "  ✓ zip: ${ZIP_PATH}"

# 输出 checksum（用于 SPM binary target）
echo ""
echo "▶ Checksum (用于 SPM binary target):"
swift package compute-checksum "${ZIP_PATH}" 2>/dev/null || shasum -a 256 "${ZIP_PATH}"
