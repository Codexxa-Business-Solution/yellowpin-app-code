# Fixing "Connection timeout" / "Connection refused"

If the app shows **ClientException** with **SocketException: connection timeout** (or connection refused) when calling the Laravel API:

## 1. Start Laravel so it accepts connections from the emulator/device

From the **Laravel project root** (e.g. `d:\Yellow Pin 03-03`), run:

```bash
php artisan serve --host=0.0.0.0
```

- **Do not** use only `php artisan serve` when testing from Android emulator or a physical device.
- `--host=0.0.0.0` makes Laravel listen on all network interfaces so the emulator (10.0.2.2) or your phone can reach it.
- Leave this terminal open while testing.

## 2. Check from your PC first

In a browser on the **same PC** where Laravel is running, open:

- **http://localhost:8000** or **http://127.0.0.1:8000**

**Do not** open `http://0.0.0.0:8000` in the browser—`0.0.0.0` is only for the server to listen on; it is not a valid address to visit.

If Laravel is running, you should see the Laravel welcome page or your app. You can also try http://localhost:8000/api/v1/verify-with-phone (you may see "Method Not Allowed" for GET—that’s fine; it means the server is up).

## 3. Android Emulator

- The app uses **10.0.2.2:8000** to reach your PC from the emulator.
- If it still times out, **Windows Firewall** may be blocking port 8000:
  - Open Windows Defender Firewall → Advanced settings → Inbound Rules.
  - New Rule → Port → TCP, 8000 → Allow. Apply to your network profile.

## 4. Physical Android/iOS device

- **10.0.2.2** only works inside the Android **emulator**. On a real phone it will timeout.
- On your PC, find your IP (e.g. `ipconfig` → IPv4 like 192.168.1.5).
- In `lib/core/api/api_config.dart`, set:
  ```dart
  static const String? useCustomHost = '192.168.1.5';  // your PC's IP
  ```
- Ensure phone and PC are on the **same Wi‑Fi**.
- Run Laravel with: `php artisan serve --host=0.0.0.0`
- If it still times out, add a firewall rule for port 8000 (see step 3).

## 5. iOS Simulator

- Uses **localhost**. Run: `php artisan serve` (or `--host=0.0.0.0`). No config change needed.
