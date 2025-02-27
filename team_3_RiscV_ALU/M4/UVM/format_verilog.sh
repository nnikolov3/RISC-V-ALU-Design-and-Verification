#!/bin/bash
# ----------------------------------------------------------------------------
# Script: Verible Verilog Formatter with Safe Alignment
# Date: February 26, 2025
# Description:
#   Formats *.sv files with Verible, aligns = in simple signal declarations to
#   column 32, places // comments 2 spaces after code (left-aligned), converts
#   /* */ to // ---- blocks, limits blank lines to one, uses 4-space indentation,
#   and backs up files. Avoids breaking code by preserving complex lines.
# Usage:
#   ./format_verilog.sh
# ----------------------------------------------------------------------------

# ------------------------------------------------------------------------
# Tool Check
# Description:
#   Ensures verible-verilog-format is installed.
# ------------------------------------------------------------------------
if ! command -v verible-verilog-format &> /dev/null; then
    echo "Error: verible-verilog-format not found. Please install it first."
    exit 1
fi

# ------------------------------------------------------------------------
# File Check
# Description:
#   Verifies at least one .sv file exists in the current directory.
# ------------------------------------------------------------------------
if ! ls *.sv >/dev/null 2>&1; then
    echo "No .sv files found in the current directory."
    exit 1
fi

# ------------------------------------------------------------------------
# Backup Setup
# Description:
#   Creates a timestamped backup directory for original files.
# ------------------------------------------------------------------------
BACKUP_DIR="verilog_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Backup directory created: $BACKUP_DIR"

# ------------------------------------------------------------------------
# Alignment Function
# Description:
#   Aligns = to column 32 in simple signal declarations, places // comments 2
#   spaces after code, converts /* */ to blocks, and preserves other code.
# ------------------------------------------------------------------------
align_code() {
    local file="$1"
    awk '
    BEGIN { in_multiline=0 }
    # Convert multi-line /* */ comments
    /^\/\*/ && !/\*\// {
        in_multiline=1
        sub(/^\/\*[[:space:]]*/, "")
        print "// ----------------------------------------------------------------------------"
        print "// " $0
        next
    }
    in_multiline && /\*\// {
        in_multiline=0
        sub(/[[:space:]]*\*\//, "")
        if ($0 !~ /^[[:space:]]*$/) print "// " $0
        print "// ----------------------------------------------------------------------------"
        next
    }
    in_multiline {
        sub(/^[[:space:]]*/, "")
        if ($0 !~ /^[[:space:]]*$/) print "// " $0
        next
    }
    # Convert single-line /* */ comments
    /^\/\*/ && /\*\// {
        sub(/^\/\*[[:space:]]*/, "")
        sub(/[[:space:]]*\*\//, "")
        print "// ----------------------------------------------------------------------------"
        print "// " $0
        print "// ----------------------------------------------------------------------------"
        next
    }
    # Align simple signal declarations with = (no multi-line, no comparisons)
    /^[[:space:]]*(bit|logic|int|rand)\s*(\[.*\])?\s+[a-zA-Z0-9_]+\s*=[^=;]*$/ {
        indent=substr($0, 1, match($0, /[^[:space:]]/)-1)
        signal=substr($0, match($0, /[^[:space:]]/), match($0, /=/)-match($0, /[^[:space:]]/)+1)
        value=substr($0, match($0, /=/)+1)
        comment=""
        if (match($0, /\/\//)) {
            value=substr($0, match($0, /=/)+1, match($0, /\/\//)-match($0, /=/)-1)
            comment=substr($0, match($0, /\/\//))
            sub(/^[[:space:]]+/, "", comment)
        }
        sub(/^[[:space:]]+/, "", value)
        if (length(signal) <= 31) {
            if (comment) {
                printf "%s%-31s = %s  %s\n", indent, signal, value, comment
            } else {
                printf "%s%-31s = %s\n", indent, signal, value
            }
        } else {
            print $0
        }
        next
    }
    # Align standalone // comments
    /^[[:space:]]*\/\// {
        indent=substr($0, 1, match($0, /\/\//)-1)
        comment=substr($0, match($0, /\/\//))
        sub(/^[[:space:]]+/, "", comment)
        printf "%s%s\n", indent, comment
        next
    }
    # Preserve other lines unchanged (e.g., comparisons, multi-line assignments)
    { print $0 }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# ------------------------------------------------------------------------
# File Processing Loop
# Description:
#   Processes each .sv file: backs up, formats with Verible, aligns code and
#   comments, and applies final formatting rules without breaking code.
# ------------------------------------------------------------------------
for file in *.sv; do
    echo "Processing: $file"
    cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
    echo "  Backup created: $BACKUP_DIR/$(basename "$file").bak"
    verible-verilog-format \
        --inplace \
        --indentation_spaces=4 \
        --column_limit=100 \
        "$file"
    if [ $? -eq 0 ]; then
        echo "  Formatted with Verible: $file"
        align_code "$file"  # Align = in simple declarations, and comments
        sed -i 's/[[:space:]]*$//' "$file"  # Remove trailing spaces
        expand -t 4 "$file" > "$file.tmp" && mv "$file.tmp" "$file"  # 4 spaces, no tabs
        awk 'BEGIN {blanks=0} !NF {blanks++; if (blanks<=1) print ""; next} {blanks=0; print}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"  # One blank line max
        echo "  Alignment and formatting complete: $file"
    else
        echo "  Error formatting: $file - restoring backup"
        cp "$BACKUP_DIR/$(basename "$file").bak" "$file"
    fi
done

# ------------------------------------------------------------------------
# Completion Message
# Description:
#   Indicates that all processing is complete.
# ------------------------------------------------------------------------
echo "Formatting and alignment complete!"