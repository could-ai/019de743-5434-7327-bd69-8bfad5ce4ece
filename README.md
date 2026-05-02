# Proforma Invoice Generator

A complete solution to capture customer data via a shareable link, sync it to Google Sheets, and automatically generate a professional Proforma Invoice PDF with an embedded E-Signature.

## Features
- **Smart Customer Form**: Shareable link to capture customer details, products, and terms.
- **Proforma Invoice PDF Generation**: Auto-generates a downloadable PDF using `pdf` and `printing` packages.
- **E-Signature Support**: Upload a signature in settings, which is automatically placed on every generated invoice.
- **Google Sheets Sync**: Submissions trigger a Supabase Edge Function that pushes the data to a configured Google Apps Script Webhook for real-time synchronization.
- **Dashboard**: View all past invoices and check their sync status.
- **Settings Panel**: Easily manage your Google Sheets Webhook URL and authorized signatory image.

## Tech Stack
- **Frontend**: Flutter (Web, iOS, Android, macOS, Windows, Linux)
- **Routing**: GoRouter
- **Database & Auth**: Supabase
- **Functions**: Supabase Edge Functions (Deno)
- **PDF Generation**: `pdf`, `printing`

## Setup Instructions

1. **Connect Supabase Project**: Ensure a Supabase project is linked via CouldAI.
2. **Deploy Database Schema**: The initial migrations will automatically configure the `invoices` and `settings` tables, along with a `signatures` storage bucket.
3. **Deploy Edge Function**: The `sync_to_sheets` edge function handles pushing data to your webhook.
4. **Google Sheets Webhook**:
    - Create a new Google Sheet.
    - Go to Extensions > Apps Script.
    - Add a `doPost(e)` function to parse the incoming JSON payload and append a row to the active sheet.
    - Deploy as a Web App (access: "Anyone").
    - Copy the Web App URL and paste it into the app's Settings screen.
5. **Run the App**:
   ```bash
   flutter run -d chrome
   ```

## User Flows

1. **Submit Invoice Request**: Users land on the form screen (`/`), fill in their details, and submit.
2. **PDF Preview**: Upon submission, they are navigated to the success screen (`/success`) where a dynamic PDF is rendered. They can download or print it.
3. **Admin Dashboard**: Accessible via the dashboard icon (`/dashboard`), admins can view all submissions and see whether they synced successfully to Google Sheets.

---

## About CouldAI
This application was generated with [CouldAI](https://could.ai), an AI app builder for cross-platform apps that turns prompts into real native iOS, Android, Web, and Desktop apps with autonomous AI agents that architect, build, test, deploy, and iterate production-ready applications.