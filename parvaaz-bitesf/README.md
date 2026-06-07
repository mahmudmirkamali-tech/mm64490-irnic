# موسسه پرواز — PWA دستیار حقوقی هوشمند

پلتفرم چندخدماتی (حقوق، بیمه، بورس، رمزارز، کارپردازی) با دستیار هوشمند AI.

**دامنه‌ها:** [bitesf.ir](https://bitesf.ir) · [presf.ir](https://presf.ir)  
**هسته ابری رایگان:** Cloudflare Pages + Functions

راهنمای کامل استقرار: [DEPLOY.md](DEPLOY.md)

## راه‌اندازی سریع

### ۱. کلید API

فایل `config.json` را باز کنید و کلید Anthropic خود را وارد کنید:

```json
{
  "anthropic_api_key": "sk-ant-api03-..."
}
```

کلید را از [console.anthropic.com](https://console.anthropic.com/) دریافت کنید.

### ۲. اجرای سرور

روی فایل **`start.bat`** دوبار کلیک کنید، یا در PowerShell:

```powershell
cd Desktop\parvaaz-bitesf
powershell -ExecutionPolicy Bypass -File server.ps1
```

### ۳. باز کردن در مرورگر

به آدرس زیر بروید:

**http://localhost:3000**

## نصب به‌صورت اپ (PWA)

1. سایت را در Chrome یا Edge باز کنید
2. از منوی مرورگر گزینه **Install app** / **نصب** را بزنید
3. یا بنر «نصب» پایین صفحه را بپذیرید

## ساختار پروژه

```
parvaaz-bitesf/
├── index.html      # اپ اصلی
├── manifest.json   # تنظیمات PWA
├── sw.js           # Service Worker (آفلاین)
├── server.ps1      # سرور محلی + پروکسی API
├── config.json     # کلید API (محرمانه)
├── start.bat       # اجرای سریع
└── icons/          # آیکون‌های اپ
```

## نکات

- بدون سرور محلی، Service Worker و چت AI کار نمی‌کند (فایل HTML مستقیم باز نشود)
- `config.json` را در گیت commit نکنید
- پورت پیش‌فرض: **3000**
