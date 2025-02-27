#!/bin/bash

# Script to generate a linting report for all .sv files using verible-verilog-lint

# Output report file
REPORT_FILE="lint_report_$(date +%Y%m%d_%H%M%S).txt"
TEMP_FILE="temp_output.txt"

# Default configuration
RULES_CONFIG=""
AUTOFIX="no"
CHECK_SYNTAX="true"
LINT_FATAL="false"  # Set to false to continue processing all files even with violations

# Check if verible-verilog-lint is installed
if ! command -v verible-verilog-lint &> /dev/null; then
    echo "Error: verible-verilog-lint not found. Please install it first."
    exit 1
fi

# Check if there are any .sv files in the current directory
if ! ls *.sv >/dev/null 2>&1; then
    echo "Error: No .sv files found in the current directory"
    exit 1
fi

# Header for the report
echo "Verilog/SystemVerilog Linting Report" > "$REPORT_FILE"
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

    echo "Linting file: $file" >> "$REPORT_FILE"
    echo "-------------" >> "$REPORT_FILE"

    # Run verible-verilog-lint with configured options
    # Ensure no trailing spaces after backslashes and proper line continuation
    verible-verilog-lint \
        --check_syntax="$CHECK_SYNTAX" \
        --lint_fatal="$LINT_FATAL" \
        --parse_fatal="false" \
        --show_diagnostic_context \
        ${RULES_CONFIG:+--rules_config="$RULES_CONFIG"} \
        --autofix="$AUTOFIX" \
        "$file" > "$TEMP_FILE" 2>&1

    # Check if there were any linting issues
    if [ -s "$TEMP_FILE" ]; then  # If temp file has content
        # Include all linting messages
        cat "$TEMP_FILE" >> "$REPORT_FILE"
    else
        echo "No linting issues found" >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
done

# Clean up temporary file
rm -f "$TEMP_FILE"

# Footer
echo "===================================" >> "$REPORT_FILE"
echo "Report generation complete" >> "$REPORT_FILE"

echo "Linting report generated: $REPORT_FILE"