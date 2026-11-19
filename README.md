# Rice Mill Manager v1.1 - Flutter Android starter

## Features included
- Tamil / English toggle
- Five products: Rice Flour, Cotton Seed, SKM Feeds, KS Feed, Rice Husk
- Stock from own production and outside purchase
- Kg and Bag sales, with configurable bag weight per product
- Stock validation before sales
- Customer records (name, phone, address)
- Customer outstanding balance when sale is partly paid
- Record customer payments and reduce balance
- Sales history and basic dashboard
- PDF business summary export / print
- PDF invoice generation function is included in source; invoice printing can be connected to a sale-history action in the next UI pass
- Offline local persistence with shared_preferences

## Run on Android
1. Install Flutter SDK and Android Studio.
2. Extract this ZIP.
3. In the extracted folder run `flutter pub get`.
4. Connect an Android phone with USB debugging enabled, or start an emulator.
5. Run `flutter run`.

## Important accounting notes
This is a development starter, not a finished audited accounting product.
- PDF summary export is connected.
- Invoice PDF generation helper is implemented, but an invoice button on each sale is a follow-up UI task.
- Profit is intentionally not shown as a definitive number: accurate net profit needs expense entries and a stock valuation method.
- Data is stored locally on this device. Back up the app/device; cloud sync and restore are not included yet.
- Test calculations and invoices with sample transactions before relying on it for business records.
