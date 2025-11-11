#!/bin/bash
# Automated Terminal Testing
# Run predefined test scenarios to validate terminal configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${TESTS_DIR:-$HOME/.terminal-guru/tests}"
mkdir -p "$TESTS_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] TEST_NAME

Run automated terminal tests and compare results.

OPTIONS:
    -c, --config FILE       Use custom zshrc
    -o, --output DIR        Output directory for results
    -h, --help             Show this help

BUILT-IN TESTS:
    unicode-basic          Test basic Unicode rendering
    unicode-emoji          Test emoji rendering and backspace
    unicode-cjk           Test CJK character rendering
    box-drawing           Test box drawing characters
    color-256             Test 256 color support
    color-truecolor       Test truecolor support
    backspace-test        Interactive backspace testing
    all                   Run all tests

CUSTOM TESTS:
    Create a test file in ~/.terminal-guru/tests/ with commands to run

EXAMPLES:
    # Run Unicode emoji test
    $(basename "$0") unicode-emoji

    # Run test with custom config
    $(basename "$0") -c ~/test.zshrc unicode-basic

    # Run all tests
    $(basename "$0") all

EOF
    exit 1
}

run_test() {
    local test_name="$1"
    local output_dir="${OUTPUT_DIR:-$TESTS_DIR/results}"
    mkdir -p "$output_dir"
    
    local result_file="$output_dir/${test_name}-$(date +%Y%m%d-%H%M%S).txt"
    
    echo -e "${BLUE}Running test: $test_name${NC}"
    
    case "$test_name" in
        unicode-basic)
            test_unicode_basic "$result_file"
            ;;
        unicode-emoji)
            test_unicode_emoji "$result_file"
            ;;
        unicode-cjk)
            test_unicode_cjk "$result_file"
            ;;
        box-drawing)
            test_box_drawing "$result_file"
            ;;
        color-256)
            test_color_256 "$result_file"
            ;;
        color-truecolor)
            test_color_truecolor "$result_file"
            ;;
        backspace-test)
            test_backspace_interactive
            ;;
        all)
            run_all_tests
            ;;
        *)
            # Try to find custom test file
            if [[ -f "$TESTS_DIR/$test_name.sh" ]]; then
                bash "$TESTS_DIR/$test_name.sh" | tee "$result_file"
            else
                echo -e "${RED}Unknown test: $test_name${NC}"
                exit 1
            fi
            ;;
    esac
    
    echo -e "${GREEN}Test completed: $test_name${NC}"
    echo -e "${BLUE}Results saved to: $result_file${NC}"
}

test_unicode_basic() {
    local output="$1"
    
    cat > "$output" << 'EOF'
=== Basic Unicode Test ===

1. ASCII:
   ABCDEFGHIJKLMNOPQRSTUVWXYZ
   abcdefghijklmnopqrstuvwxyz
   0123456789

2. Latin Extended:
   àáâãäåæçèéêëìíîï
   ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ

3. Greek:
   αβγδεζηθικλμνξοπρστυφχψω

4. Cyrillic:
   абвгдежзийклмнопрстуфхцчшщыэюя
   АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЫЭЮЯ

5. Symbols:
   ←↑→↓↔ ✓✗★☆♠♣♥♦

EOF

    cat "$output"
}

test_unicode_emoji() {
    local output="$1"
    
    cat > "$output" << 'EOF'
=== Emoji Test ===

1. Simple Emoji (width 2):
   😀 😃 😄 😁 😅 😂 🤣
   ❤️ 💛 💚 💙 💜 🖤 🤍
   🎉 🎊 🎈 🎁 🎀 🎂

2. Emoji with Skin Tones:
   👍 👍🏻 👍🏼 👍🏽 👍🏾 👍🏿

3. Flags (Regional Indicators):
   🇺🇸 🇬🇧 🇯🇵 🇩🇪 🇫🇷 🇮🇹

4. Objects:
   🚀 🚁 🚂 🚃 🚄 🚅
   💻 📱 ⌨️ 🖱️ 🖥️ 📞

5. ZWJ Sequences (may not render):
   👨‍👩‍👧‍👦 👨‍💻 👩‍🔬 🏳️‍🌈

Backspace Test:
Type these and backspace:
- 😀 (should delete with one backspace)
- 🎉 (should delete with one backspace)
- ❤️ (may need two backspaces due to variation selector)

EOF

    cat "$output"
}

test_unicode_cjk() {
    local output="$1"
    
    cat > "$output" << 'EOF'
=== CJK Character Test ===

1. Chinese (Simplified):
   你好世界
   中文测试

2. Chinese (Traditional):
   你好世界
   中文測試

3. Japanese Hiragana:
   あいうえお
   かきくけこ

4. Japanese Katakana:
   アイウエオ
   カキクケコ

5. Japanese Kanji:
   日本語
   漢字

6. Korean Hangul:
   안녕하세요
   한국어

Width Test (CJK should be width 2):
|你| |好| |世| |界|
Each character should take 2 columns

EOF

    cat "$output"
}

test_box_drawing() {
    local output="$1"
    
    cat > "$output" << 'EOF'
=== Box Drawing Test ===

1. Single Line:
┌─┬─┐
│ │ │
├─┼─┤
│ │ │
└─┴─┘

2. Double Line:
╔═╦═╗
║ ║ ║
╠═╬═╣
║ ║ ║
╚═╩═╝

3. Rounded Corners:
╭─┬─╮
│ │ │
├─┼─┤
│ │ │
╰─┴─╯

4. Block Elements:
█▓▒░ ▀▄ ▌▐

5. Mixed Styles:
┏━┳━┓
┃ ┃ ┃
┣━╋━┫
┃ ┃ ┃
┗━┻━┛

If you see letters (q, x, m, j) instead of lines,
you have an ACS/UTF-8 issue.

EOF

    cat "$output"
}

test_color_256() {
    local output="$1"
    
    {
        echo "=== 256 Color Test ==="
        echo
        echo "System Colors (0-15):"
        for i in {0..15}; do
            printf "\e[48;5;%dm  \e[0m" "$i"
            if (( (i + 1) % 8 == 0 )); then echo; fi
        done
        echo
        
        echo "216 Color Cube (16-231):"
        for i in {16..231}; do
            printf "\e[48;5;%dm  \e[0m" "$i"
            if (( (i - 15) % 36 == 0 )); then echo; fi
        done
        echo
        
        echo "Grayscale (232-255):"
        for i in {232..255}; do
            printf "\e[48;5;%dm  \e[0m" "$i"
        done
        echo
        echo
    } | tee "$output"
}

test_color_truecolor() {
    local output="$1"
    
    {
        echo "=== Truecolor (24-bit) Test ==="
        echo
        echo "RGB Gradient:"
        for r in {0..255..8}; do
            printf "\e[48;2;%d;0;0m \e[0m" "$r"
        done
        echo
        for g in {0..255..8}; do
            printf "\e[48;2;0;%d;0m \e[0m" "$g"
        done
        echo
        for b in {0..255..8}; do
            printf "\e[48;2;0;0;%dm \e[0m" "$b"
        done
        echo
        echo
        
        echo "Rainbow:"
        for i in {0..255..4}; do
            r=$((255 - i))
            g=$i
            b=$((i / 2))
            printf "\e[48;2;%d;%d;%dm \e[0m" "$r" "$g" "$b"
        done
        echo
        echo
    } | tee "$output"
}

test_backspace_interactive() {
    cat << 'EOF'
=== Interactive Backspace Test ===

Instructions:
1. Type each test string below
2. Press backspace to delete characters
3. Each character should delete with ONE backspace

Test Strings:
- Hello World
- 你好世界
- 😀🎉✨
- café
- ┌─┐
- Mixed: Hello 你好 😀

Press Enter when ready, then Ctrl+D when done.
EOF

    read -r
    cat  # Allow user to type
}

run_all_tests() {
    echo -e "${BLUE}Running all tests...${NC}"
    echo
    
    for test in unicode-basic unicode-emoji unicode-cjk box-drawing color-256 color-truecolor; do
        run_test "$test"
        echo
    done
    
    echo -e "${GREEN}All tests completed${NC}"
}

# Parse options
OUTPUT_DIR=""
CUSTOM_CONFIG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CUSTOM_CONFIG="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            run_test "$1"
            exit 0
            ;;
    esac
done

usage
