# Smart Customer Invoice Generator

A complete solution for creating shareable link-based customer invoice forms, integrating with Google Sheets for tracking, and automatically generating Proforma Invoices with digital signatures in PDF format. Built with Flutter and Supabase.

## Features

- **Link-Based Customer Form**: Generate a shareable link that your customers can use to submit their invoice details.
- **Proforma Invoice Generator**: Automatically constructs a highly professional Proforma Invoice in PDF format upon form submission.
- **E-Signature Support**: Allows the business owner to upload an e-signature in the Dashboard, which gets seamlessly embedded into all generated PDFs.
- **Google Sheets Integration**: Utilizes Supabase Edge Functions to call an Apps Script webhook and append form submissions to a Google Sheet automatically.
- **Dashboard Settings**: A centralized location for managing your webhook configuration, updating the e-signature, and grabbing the form link to share.

## Tech Stack

- **Framework**: Flutter (Web, iOS, Android, macOS, Windows, Linux)
- **Database & Backend**: Supabase (PostgreSQL, Storage, Edge Functions)
- **PDF Generation**: `pdf` and `printing` packages
- **Routing**: `go_router` for seamless web and app navigation
- **File Management**: `file_picker` for signature uploads

## Setup Instructions

1. **Connect Supabase**: Ensure you have linked your Supabase project using the built-in configuration. The application runs migrations upon successful setup to create `invoices` and `settings` tables, as well as the `signatures` storage bucket.
2. **Deploy the Edge Function**: A Supabase Edge Function (`sync_to_sheets`) is provided to hit the Apps Script webhook. 
3. **Run the App**: 
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

## Google Sheets Integration Setup

To fully test Google Sheets synchronization:
1. Create a new Google Sheet.
2. Go to **Extensions > Apps Script** and insert the following code:
```javascript
function doPost(e) {
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  var data = JSON.parse(e.postData.contents);
  
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(["ID", "Customer", "Company", "Address", "Contact", "Email", "Product", "Qty", "Price", "Total", "Created At"]);
  }
  
  sheet.appendRow([
    data.id,
    data.customer_name,
    data.company_name,
    data.address,
    data.contact_number,
    data.email,
    data.product_details,
    data.quantity,
    data.price,
    data.total_amount,
    data.created_at
  ]);
  
  return ContentService.createTextOutput(JSON.stringify({"status": "success"})).setMimeType(ContentService.MimeType.JSON);
}
```
3. Deploy the Apps Script as a **Web App**, granting access to "Anyone".
4. Copy the Web App URL, navigate to your app's **Dashboard**, paste the URL into the **Google Sheets Webhook URL** field, and save it.

## User Flows

- **Business Owner**: Navigates to the root path (`/`) to access the Dashboard. Sets the Google Sheets Webhook URL and uploads a transparent PNG of their signature. Copies the customer form link.
- **Customer**: Opens the shared link (`/#/form`). Fills out their product requirement, company details, and contact info. Upon hitting submit, their info goes to Supabase, syncs to Google Sheets, and a completed Proforma Invoice PDF is automatically downloaded containing the owner's digital signature.

---

## About CouldAI

This app was generated with [CouldAI](https://could.ai), an AI app builder for cross-platform apps that turns prompts into real native iOS, Android, Web, and Desktop apps with autonomous AI agents that architect, build, test, deploy, and iterate production-ready applications.