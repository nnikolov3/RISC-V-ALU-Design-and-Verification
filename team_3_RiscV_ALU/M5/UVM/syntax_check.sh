#!/bin/bash

# Script to generate a syntax report for all .sv files using verible-verilog-syntax

# Output report file
REPORT_FILE="syntax_report_$(date +%Y%m%d_%H%M%S).txt"
TEMP_FILE="temp_output.txt"

# Check if verible-verilog-syntax is installed
if ! command -v verible-verilog-syntax &> /dev/null; then
    echo "Error: verible-verilog-syntax not found. Please install it first."
    exit 1
fi

# Check if there are any .sv files in the current directory
if ! ls *.sv >/dev/null 2>&1; then
    echo "Error: No .sv files found in the current directory"
    exit 1
fi

# Header for the report
echo "Verilog/SystemVerilog Syntax Report" > "$REPORT_FILE"
echo "Generated on: $(date)" >> "$REPORT_FILE"
echo "Directory: $(pwd)" >> "$REPORT_FILE"
echo "===================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Process each .sv file
for file in *.sv; do
    # Verify it's a regular file (not a directory, etc.)
    if [ ! -f "$file" ]; then
        echo "Warning: '$file' is not a regular file, skipping..." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        continue
    fi

    echo "Analyzing file: $file" >> "$REPORT_FILE"
    echo "----------------" >> "$REPORT_FILE"

    # Run verible-verilog-syntax with useful options
    # - Using auto language detection
    # - No error limit (0)
    # - Verifying parse tree
    verible-verilog-syntax \
        --lang=auto \
        --error_limit=0 \
        --verifytree \
        "$file" > "$TEMP_FILE" 2>&1

    # Check if there were any syntax errors
    if [ $? -ne 0 ] || grep -q "syntax error" "$TEMP_FILE"; then
        # Filter out successful parsing messages and focus on errors
        grep -v "Parsing succeeded" "$TEMP_FILE" | \
        grep -v "All tokens parsed" >> "$REPORT_FILE"
    else
        echo "No syntax issues found" >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
done

# Clean up temporary file
rm -f "$TEMP_FILE"

# Footer
echo "===================================" >> "$REPORT_FILE"
echo "Report generation complete" >> "$REPORT_FILE"

echo "Syntax report generated: $REPORT_FILE"