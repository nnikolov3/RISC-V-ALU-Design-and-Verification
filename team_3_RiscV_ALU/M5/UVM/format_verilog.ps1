# Verible Verilog Formatter Script
# Formats all *.sv files using verible-verilog-format with specified options
# Usage: .\format_verilog.ps1
# Date: $(Get-Date -Format "MMMM dd, yyyy")

# Check if verible-verilog-format is available in the current directory
if (-not (Test-Path ".\verible-verilog-format.exe")) {
    Write-Host "Error: verible-verilog-format.exe not found in the current directory. Please ensure it is present." -ForegroundColor Red
    exit 1
}

# Check for .sv files in the current directory
$svFiles = Get-ChildItem -Filter "*.sv" -File
if ($svFiles.Count -eq 0) {
    Write-Host "No .sv files found in the current directory." -ForegroundColor Yellow
    exit 1
}

# Create a timestamped backup directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "verilog_backups_$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Host "Backup directory created: $backupDir" -ForegroundColor Green

# Process each .sv file
foreach ($file in $svFiles) {
    $fileName = $file.Name
    Write-Host "Processing: $fileName"

    # Create backup
    $backupPath = Join-Path $backupDir "$fileName.bak"
    Copy-Item -Path $file.FullName -Destination $backupPath
    Write-Host "  Backup created: $backupPath" -ForegroundColor Cyan

    # Run verible-verilog-format with original options
    & ".\verible-verilog-format.exe" `
        --inplace `
        --indentation_spaces=4 `
        --column_limit=100 `
        --line_break_penalty=2 `
        --over_column_limit_penalty=1000 `
        --wrap_spaces=4 `
        --assignment_statement_alignment=align `
        --case_items_alignment=align `
        --class_member_variable_alignment=align `
        --distribution_items_alignment=align `
        --enum_assignment_statement_alignment=align `
        --formal_parameters_alignment=align `
        --formal_parameters_indentation=indent `
        --module_net_variable_alignment=align `
        --named_parameter_alignment=align `
        --named_parameter_indentation=indent `
        --named_port_alignment=align `
        --named_port_indentation=indent `
        --port_declarations_alignment=align `
        --port_declarations_indentation=indent `
        --struct_union_members_alignment=align `
        --try_wrap_long_lines=true `
        --max_search_states=100000 `
        --verify_convergence=true `
        $file.FullName

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Successfully formatted: $fileName" -ForegroundColor Green
    } else {
        Write-Host "  Error formatting: $fileName - restoring backup" -ForegroundColor Red
        Copy-Item -Path $backupPath -Destination $file.FullName -Force
    }
}

# Final message
Write-Host "Formatting complete!" -ForegroundColor Green