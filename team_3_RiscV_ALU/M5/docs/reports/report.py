import os
from fpdf import FPDF
import datetime
from PyPDF2 import PdfReader, PdfWriter


def combine_text_to_pdf(
    directory_path,
    output_pdf="team3_m5_coverage_reports.pdf",
    add_line_numbers=False,
):
    # Create PDF object
    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=10)

    # Set font to Courier (monospaced, ideal for code)
    pdf.set_font("Courier", size=10)

    # Get all text files in the directory
    text_files = [
        f for f in os.listdir(directory_path) if f.endswith(".txt")
    ]
    text_files.sort()

    # Store page numbers for bookmarks
    bookmarks = []

    # Add a title page
    pdf.add_page()
    pdf.set_font("Courier", "B", 10)
    pdf.cell(0, 10, "Coverage and Run Reports", ln=1, align="C")
    pdf.set_font("Courier", size=10)
    pdf.cell(
        0,
        10,
        f"Generated on: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        ln=1,
        align="C",
    )
    pdf.cell(0, 10, f"Total Files: {len(text_files)}", ln=1, align="C")
    pdf.ln(10)
    bookmarks.append(("Table of Contents", 1))  # Page 1 for TOC

    # Process each text file
    for text_file in text_files:
        file_path = os.path.join(directory_path, text_file)

        # Start new page and record page number
        pdf.add_page()
        page_num = pdf.page_no()
        bookmarks.append((text_file, page_num))

        # Add file name as header
        pdf.set_font("Courier", "B", 10)
        pdf.cell(0, 10, f"File: {text_file}", ln=1)
        pdf.ln(5)

        # Read and add content
        pdf.set_font("Courier", size=10)
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                for i, line in enumerate(lines, 1):
                    line_text = line.rstrip("\n")
                    if add_line_numbers:
                        line_text = f"{i:4d} | {line_text}"
                    pdf.multi_cell(0, 6, line_text, border=0)
        except Exception as e:
            pdf.multi_cell(0, 6, f"Error reading {text_file}: {str(e)}")

        pdf.ln(10)

    # Save initial PDF
    temp_pdf = "temp_team3_m5_coverage_reports.pdf"
    pdf.output(temp_pdf)

    # Add bookmarks using PyPDF2
    reader = PdfReader(temp_pdf)
    writer = PdfWriter()

    # Copy all pages
    for page in reader.pages:
        writer.add_page(page)

    # Add bookmarks using the new method
    toc_bookmark = writer.add_outline_item(
        "Table of Contents", 0
    )  # Page 0 in PyPDF2
    for title, page_num in bookmarks[1:]:  # Skip TOC itself
        writer.add_outline_item(
            title, page_num - 1, parent=toc_bookmark
        )  # -1 for 0-based indexing

    # Save final PDF with bookmarks
    try:
        with open(output_pdf, "wb") as f:
            writer.write(f)
        os.remove(temp_pdf)  # Clean up temporary file
        print(f"PDF successfully created: {output_pdf}")
        print(f"Combined {len(text_files)} text files")
        print("Bookmarks added for each file")
    except Exception as e:
        print(f"Error creating PDF: {str(e)}")


if __name__ == "__main__":
    directory = os.getcwd()
    combine_text_to_pdf(
        directory, "team3_m5_coverage_reports.pdf", add_line_numbers=False
    )
