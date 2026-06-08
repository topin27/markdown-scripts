#!/bin/bash

# 开启错误即退和未定义变量报错
set -eu

# 帮助信息函数
usage() {
    local exit_code="${1:-0}"
    local stream=1
    if [ "$exit_code" -ne 0 ]; then
        stream=2
    fi

    {
        echo "Usage: $0 [OPTIONS] <input_file>"
        echo "Compile a Markdown file to HTML using pandoc with custom filters and template."
        echo ""
        echo "Options:"
        echo "  -o <output_file>  Path to the output HTML file (required)."
        echo "  -h                Display this help message and exit."
        echo ""
        echo "Example:"
        echo "  $0 -o output.html input.md"
    } >&"$stream"
    exit "$exit_code"
}

# 默认值
INPUT_FILE=""
OUTPUT_FILE=""

# 使用标准 getopts 解析参数
while getopts "o:h" opt; do
  case $opt in
    o)
      OUTPUT_FILE="$OPTARG"
      ;;
    h)
      usage 0
      ;;
    ?)
      usage 1
      ;;
  esac
done
shift $((OPTIND - 1))

# 获取位置参数（输入文件）
INPUT_FILE="${1:-}"

# 验证必要参数
if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Error: Input file and output file are required." >&2
    exit 1
fi

# --- 1. 路径验证与设置 ---
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found at '$INPUT_FILE'" >&2
    exit 1
fi

# 获取绝对路径
ABS_INPUT_FILE="$(realpath "$INPUT_FILE")"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LINK_FILTER_SCRIPT="${SCRIPT_DIR}/process_links.py"
DIAGRAM_FILTER_SCRIPT="${SCRIPT_DIR}/process_diagrams.py"
TEMPLATE_FILE="${SCRIPT_DIR}/assets/template.html"

# 检查依赖文件
if [ ! -f "$LINK_FILTER_SCRIPT" ]; then
    echo "Error: Link filter script not found at '$LINK_FILTER_SCRIPT'" >&2
    exit 1
fi

if [ ! -f "$DIAGRAM_FILTER_SCRIPT" ]; then
    echo "Error: Diagram filter script not found at '$DIAGRAM_FILTER_SCRIPT'" >&2
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Custom template file not found at '$TEMPLATE_FILE'" >&2
    exit 1
fi

# --- 2. 执行 Pandoc 编译 ---
echo "Compiling '$INPUT_FILE' to '$OUTPUT_FILE'..."

pandoc \
    "$ABS_INPUT_FILE" \
    --standalone \
    --toc \
    -N \
    --mathml \
    --metadata "source_file=$ABS_INPUT_FILE" \
    --filter "$LINK_FILTER_SCRIPT" \
    --filter "$DIAGRAM_FILTER_SCRIPT" \
    --template "$TEMPLATE_FILE" \
    -o "$OUTPUT_FILE"

echo "Compilation successful!"
