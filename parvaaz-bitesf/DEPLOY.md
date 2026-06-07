# استقرار روی bitesf.ir و presf.ir

## هسته ابری رایگان: Cloudflare Pages

این پروژه برای استقرار روی **Cloudflare Pages** (رایگان) آماده است:
- میزبانی استاتیک نامحدود
- API چت در `functions/api/chat.js`
- پشتیبانی از هر دو دامنه

---

## مرحله ۱ — آپلود پروژه

### روش A: از GitHub
1. پروژه را در GitHub آپلود کنید
2. وارد [dash.cloudflare.com](https://dash.cloudflare.com) شوید
3. **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
4. ریپو را انتخاب کنید
5. Build settings:
   - **Framework preset:** None
   - **Build command:** (خالی)
   - **Build output directory:** `/`

### روش B: آپلود مستقیم
```bash
npm install -g wrangler
wrangler login
wrangler pages deploy . --project-name=parvaaz-bitesf
```

---

## مرحله ۲ — کلید API

در Cloudflare Pages → پروژه → **Settings** → **Environment variables**:

| نام | مقدار |
|-----|-------|
| `ANTHROPIC_API_KEY` | `sk-ant-api03-...` |

برای Production و Preview هر دو را تنظیم کنید.

---

## مرحله ۳ — اتصال دامنه‌ها

در **Custom domains** هر دو را اضافه کنید:

| دامنه | نوع |
|-------|-----|
| `bitesf.ir` | Apex |
| `www.bitesf.ir` | CNAME |
| `presf.ir` | Apex |
| `www.presf.ir` | CNAME |

Cloudflare DNS records را خودکار می‌سازد. اگر دامنه‌ها جای دیگری هستند:

```
bitesf.ir      →  CNAME  parvaaz-bitesf.pages.dev
www.bitesf.ir  →  CNAME  parvaaz-bitesf.pages.dev
presf.ir       →  CNAME  parvaaz-bitesf.pages.dev
www.presf.ir   →  CNAME  parvaaz-bitesf.pages.dev
```

برای Apex (بدون www) در برخی رجیسترارها از **A record** به IPهای Cloudflare استفاده کنید.

---

## مرحله ۴ — SSL

Cloudflare به‌صورت خودکار SSL رایگان فعال می‌کند.  
HTTPS اجباری: **SSL/TLS** → **Full (strict)**

---

## جایگزین رایگان: Vercel

```bash
npm i -g vercel
vercel --prod
```

در Vercel → Settings → Environment Variables:
`ANTHROPIC_API_KEY` را اضافه کنید.

هر دو دامنه را در **Domains** وصل کنید.

---

## تست محلی

```bat
start.bat
```

باز کنید: http://localhost:3000

---

## ساختار اتصال

```
کاربر (موبایل/دسکتاپ)
    ↓
bitesf.ir  یا  presf.ir
    ↓
Cloudflare Pages (رایگان)
    ├── index.html + PWA
    └── /api/chat → Anthropic API
```

هر دو دامنه **همان اپ** را نشان می‌دهند. نام دامنه در UI به‌صورت خودکار تنظیم می‌شود.
