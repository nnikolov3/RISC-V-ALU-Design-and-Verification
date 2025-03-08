# Get all .sv files in the current directory
$svFiles = Get-ChildItem -Filter "*.sv"

if ($svFiles.Count -eq 0) {
    Write-Host "No .sv files found. Nothing to format!"
    exit
}

foreach ($file in $svFiles) {
    Write-Host "Formatting $($file.Name)..."

    # Define the command as an array for clarity and proper argument passing
    $command = @(
        "verible-verilog-format"
        "--inplace"
        "--column_limit=100"
        "--indentation_spaces=2"
        "--wrap_spaces=4"
        "--assignment_statement_alignment=align"
        "--case_items_alignment=align"
        "--formal_parameters_alignment=align"
        "--formal_parameters_indentation=indent"
        "--module_net_variable_alignment=align"
        "--named_parameter_alignment=align"
        "--named_port_alignment=align"
        "--port_declarations_alignment=align"
        "--port_declarations_indentation=indent"
        "--compact_indexing_and_selections"  # Boolean, no 'true' needed
        "--try_wrap_long_lines"              # Boolean
        "--verify_convergence"               # Boolean
        $file.FullName
    )

    # Echo the command for debugging
    Write-Host "Running: $command"

    # Execute the command
    & $command[0] $command[1..($command.Length - 1)]

    if ($LASTEXITCODE -eq 0) {
        Write-Host "$($file.Name) formatted successfully!"
    }
    else {
        Write-Host "Failed to format $($file.Name). Checking why..."
        Write-Host "Exit code: $LASTEXITCODE"
    }
}
