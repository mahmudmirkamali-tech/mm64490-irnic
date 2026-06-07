# DNS — presf.ir (NetAfraz)

## نیم‌سرورها (از طرف هاست تنظیم شده)

| نیم‌سرور | IP |
|----------|-----|
| `irns1.netafraz.com` | 185.78.22.2 |
| `irns2.netafraz.com` | 149.202.28.110 |

در رجیسترار دامنه فقط همین دو نیم‌سرور را داشته باشید — نیازی به تنظیم دستی A record در رجیسترار نیست.

## IP سایت (مدیریت در cPanel هاست)

| IP |
|----|
| 185.106.201.36 |
| 185.106.201.40 |

این IPها توسط NetAfraz به `presf.ir` اختصاص داده شده‌اند.

## بعد از DNS

1. `hosting.config.json` → رمز FTP
2. `config.json` → کلید Anthropic
3. `npm run deploy:host` یا `deploy-ftp.ps1`
4. SSL در cPanel فعال کنید

سایت: **https://presf.ir**
