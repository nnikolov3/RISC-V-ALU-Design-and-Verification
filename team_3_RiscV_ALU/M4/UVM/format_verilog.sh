#!/bin/bash
/* Date: February 26, 2025 */
# Verible Verilog Formatter Script
# Formats all *.sv files in the current directory with 8-space alignment
# Usage: ./format_verilog.sh

# Check if verible-verilog-format is installed
if ! command -v verible-verilog-format &> /dev/null; then
    echo "Error: verible-verilog-format not found. Please install it first."
    exit 1
fi

# Check for .sv files in the current directory
if ! ls *.sv >/dev/null 2>&1; then
    echo "No .sv files found in the current directory."
    exit 1
fi

# Create a timestamped backup directory
BACKUP_DIR="verilog_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Backup directory created: $BACKUP_DIR"

# Process each .sv file
for file in *.sv; do
    echo "Processing: $file"
    cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
    echo "  Backup created: $BACKUP_DIR/$(basename "$file").bak"
    verible-verilog-format \
        --inplace \
        --indentation_spaces=8 \
        --column_limit=100 \
        --line_break_penalty=2 \
        --over_column_limit_penalty=1000 \
        --wrap_spaces=8 \
        --assignment_statement_alignment=align \
        --case_items_alignment=align \
        --class_member_variable_alignment=align \
        --distribution_items_alignment=align \
        --enum_assignment_statement_alignment=align \
        --formal_parameters_alignment=align \
        --formal_parameters_indentation=indent \
        --module_net_variable_alignment=align \
        --named_parameter_alignment=align \
        --named_parameter_indentation=indent \
        --named_port_alignment=align \
        --named_port_indentation=indent \
        --port_declarations_alignment=align \
        --port_declarations_indentation=indent \
        --struct_union_members_alignment=align \
        --try_wrap_long_lines=true \
        --max_search_states=100000 \
        --verify_convergence=true \
        "$file"
    if [ $? -eq 0 ]; then
        echo "  Successfully formatted: $file"
        sed -i 's/[[:space:]]*$//' "$file"
        awk 'BEGIN {blanks=0} !NF {blanks++; if (blanks<=1) print ""; next} {blanks=0; print}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
        echo "  Error formatting: $file - restoring backup"
        cp "$BACKUP_DIR/$(basename "$file").bak" "$file"
    fi
done

# Final message
echo "Formatting complete!"