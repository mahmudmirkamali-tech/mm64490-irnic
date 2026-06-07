# استقرار presf.ir روی NetAfraz (irwebspace)

## اطلاعات هاست

| مورد | مقدار |
|------|-------|
| دامنه | presf.ir |
| کاربری cPanel/FTP | `presfir` |
| سرور | `server41c.irwebspace.com` |
| پنل | https://server41c.irwebspace.com:2083 |
| نیم‌سرور ۱ | `irns1.netafraz.com` (185.78.22.2) |
| نیم‌سرور ۲ | `irns2.netafraz.com` (149.202.28.110) |

نیم‌سرورها معمولاً از طرف هاست تنظیم شده‌اند — نیازی به تغییر در رجیسترار نیست.

## مرحله ۱ — کلید API

در `config.json` (محلی):

```json
{
  "anthropic_api_key": "sk-ant-api03-..."
}
```

## مرحله ۲ — رمز FTP

در `hosting.config.json` رمز FTP/cPanel را بگذارید (از پنل هاست → FTP Accounts).

## مرحله ۳ — آپلود

```powershell
cd Desktop\parvaaz-bitesf
powershell -ExecutionPolicy Bypass -File deploy-ftp.ps1
```

یا:

```bat
npm run deploy:host
```

## مرحله ۴ — دامنه در cPanel

1. وارد cPanel شوید
2. **Domains** → `presf.ir` باید به `public_html` اشاره کند
3. **SSL/TLS** → Let's Encrypt برای presf.ir فعال کنید

## ساختار روی سرور

```
public_html/
├── index.html
├── .htaccess
├── api/
│   ├── chat.php      ← پروکسی AI
│   ├── secrets.php   ← کلید API (محافظت‌شده)
│   └── .htaccess
├── icons/
├── manifest.json
├── sw.js
└── ...
```

## تست

- https://presf.ir — صفحه اصلی
- تب AI — ارسال پیام تست
