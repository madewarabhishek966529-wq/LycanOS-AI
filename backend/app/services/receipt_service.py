"""
Generates a simple, thermal-printer-friendly PDF receipt for a completed
invoice. Deliberately narrow (80mm width, matching common thermal
printers) rather than A4 — a full-page receipt is a business email
attachment, not a POS printout. Kept dependency-light with fpdf2 rather
than a heavier templating engine, since a receipt has no images/branding
requirements yet (custom invoice branding is a Settings-phase feature).
"""
from decimal import Decimal

from fpdf import FPDF

from app.models.business import Business
from app.models.invoice import Invoice

RECEIPT_WIDTH_MM = 80


def _money(value: Decimal) -> str:
    return f"Rs. {value:.2f}"


def generate_receipt_pdf(invoice: Invoice, business: Business) -> bytes:
    pdf = FPDF(orientation="P", unit="mm", format=(RECEIPT_WIDTH_MM, 200 + len(invoice.line_items) * 6))
    pdf.set_auto_page_break(auto=False)
    pdf.add_page()
    pdf.set_margins(4, 4, 4)

    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 6, business.name, align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "", 8)
    # Business.address / Business.gst_number don't exist yet — they're
    # added in the Settings phase. Read defensively so this receipt keeps
    # working unchanged once those columns land, without depending on them
    # now.
    address = getattr(business, "address", None)
    gst_number = getattr(business, "gst_number", None)
    if address:
        pdf.multi_cell(0, 4, address, align="C")
    if gst_number:
        pdf.cell(0, 4, f"GSTIN: {gst_number}", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.ln(2)
    pdf.cell(0, 4, "-" * 42, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "", 8)
    pdf.cell(0, 4, f"Invoice: {invoice.invoice_number}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 4, f"Date: {invoice.created_at.strftime('%d-%b-%Y %I:%M %p')}", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 4, "-" * 42, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "B", 8)
    pdf.cell(38, 4, "Item")
    pdf.cell(10, 4, "Qty", align="R")
    pdf.cell(14, 4, "Rate", align="R")
    pdf.cell(14, 4, "Total", align="R", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 2, "-" * 42, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "", 8)
    for line in invoice.line_items:
        name = line.product_name if len(line.product_name) <= 20 else line.product_name[:18] + "…"
        pdf.cell(38, 4, name)
        pdf.cell(10, 4, str(line.quantity), align="R")
        pdf.cell(14, 4, f"{line.unit_price:.2f}", align="R")
        pdf.cell(14, 4, f"{line.line_total:.2f}", align="R", new_x="LMARGIN", new_y="NEXT")

    pdf.cell(0, 2, "-" * 42, new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "", 8)
    pdf.cell(62, 4, "Subtotal", align="R")
    pdf.cell(14, 4, _money(invoice.subtotal), align="R", new_x="LMARGIN", new_y="NEXT")

    if invoice.discount_amount > 0:
        pdf.cell(62, 4, "Discount", align="R")
        pdf.cell(14, 4, f"-{_money(invoice.discount_amount)}", align="R", new_x="LMARGIN", new_y="NEXT")

    pdf.cell(62, 4, "GST", align="R")
    pdf.cell(14, 4, _money(invoice.gst_amount), align="R", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "B", 10)
    pdf.cell(62, 6, "TOTAL", align="R")
    pdf.cell(14, 6, _money(invoice.total_amount), align="R", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("Helvetica", "", 8)
    pdf.ln(1)
    if invoice.is_split_payment:
        for split in invoice.payment_splits:
            pdf.cell(62, 4, split.method.value.upper(), align="R")
            pdf.cell(14, 4, _money(split.amount), align="R", new_x="LMARGIN", new_y="NEXT")
    else:
        pdf.cell(0, 4, f"Paid via {invoice.payment_method.value.upper()}", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.ln(3)
    pdf.set_font("Helvetica", "I", 8)
    pdf.cell(0, 4, "Thank you for your business!", align="C")

    output = pdf.output()
    return bytes(output)
