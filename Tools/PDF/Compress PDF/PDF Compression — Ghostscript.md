> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
https://ghostscript.com/
(Download): https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10071/gs10071w64.exe
> مرجع سريع لضغط ملفات PDF باستخدام **Ghostscript** من CMD / Cmder.

---

# 🛠️ Ghostscript

Ghostscript من أفضل الأدوات لضغط وتحسين ملفات PDF من خلال الـ Command Line.

مفيد خصوصًا مع:

- 📚 الكتب والملفات التعليمية
    
- 🖨️ ملفات الطباعة
    
- 📷 ملفات PDF الممسوحة Scanner
    
- 📄 ملفات Word / Canva / InDesign المصدّرة إلى PDF
    
- 🌐 ملفات PDF التي تريد رفعها على موقع
    
- 📧 ملفات PDF الكبيرة التي تريد إرسالها
    

---

# ⭐ أفضل أمر للاستخدام اليومي

ملف واحد:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

مجموعة ملفات:

```bash
for %F in (*.pdf) do gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="compressed\%~nF.pdf" "%F"
```
### ماذا يفعل؟

- `gswin64c` → تشغيل Ghostscript على Windows.
    
- `-sDEVICE=pdfwrite` → إنشاء ملف PDF جديد.
    
- `-dCompatibilityLevel=1.4` → تحديد إصدار التوافق مع PDF.
    
- `-dPDFSETTINGS=/ebook` → ضغط مناسب للقراءة على الشاشة.
    
- `-dNOPAUSE` → لا يتوقف بين الصفحات.
    
- `-dQUIET` → يقلل الرسائل التي تظهر في CMD.
    
- `-dBATCH` → ينهي العملية تلقائيًا بعد الانتهاء.
    
- `-sOutputFile=compressed.pdf` → اسم الملف الناتج.
    
- `input.pdf` → ملف الـ PDF الأصلي.
    

---

# 🎯 مستويات الضغط

Ghostscript يوفر Presets جاهزة للضغط:

```text
/screen
/ebook
/printer
/prepress
/default
```

## 📊 الفرق بينها

| Preset      | حجم الملف       | الجودة | الاستخدام      |
| ----------- | --------------- | ------ | -------------- |
| `/screen`   | ⭐⭐⭐⭐⭐ صغير جدًا | ⭐⭐     | شاشة / معاينة  |
| `/ebook`    | ⭐⭐⭐⭐            | ⭐⭐⭐⭐   | ⭐ أفضل توازن   |
| `/printer`  | ⭐⭐⭐             | ⭐⭐⭐⭐   | طباعة جيدة     |
| `/prepress` | ⭐⭐              | ⭐⭐⭐⭐⭐  | طباعة احترافية |
| `/default`  | ⭐⭐⭐             | ⭐⭐⭐    | استخدام عام    |

---

# 🟢 `/screen`

أقوى ضغط وحجم صغير جدًا.

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

### استخدمه عندما:

- تريد أصغر حجم ممكن.
    
- الملف للعرض على الشاشة فقط.
    
- تريد إرساله بسرعة.
    
- الجودة العالية ليست مهمة جدًا.
    

⚠️ قد يقلل جودة الصور والنصوص الممسوحة بشكل واضح.

---

# ⭐ `/ebook` — أفضل خيار

أفضل توازن بين:

**الحجم + الجودة**

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

### استخدمه عندما:

- الملف للقراءة.
    
- تريد رفعه على Website.
    
- تريد إرساله عبر WhatsApp / Email.
    
- تريد تقليل الحجم مع الحفاظ على جودة جيدة.
    

### ⭐ هذا هو الأمر الذي أستخدمه غالبًا.

---

# 🖨️ `/printer`

جودة أعلى ومناسب للطباعة:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

### استخدمه عندما:

- الملف سيُطبع.
    
- تريد الحفاظ على جودة جيدة للصور والنصوص.
    
- الحجم ليس أهم شيء.
    

---

# 🏆 `/prepress`

جودة عالية جدًا للطباعة الاحترافية:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

### استخدمه عندما:

- الملف للطباعة الاحترافية.
    
- تحتاج أعلى جودة ممكنة.
    
- حجم الملف ليس مشكلة كبيرة.
    

---

# 📄 `/default`

إعداد عام:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

مناسب عندما لا تعرف أي Preset تختار.

---

# 🧠 كيف أختار بسرعة؟

```text
للويب / Email / القراءة
→ /ebook ⭐

أصغر حجم ممكن
→ /screen

للطباعة
→ /printer

للطباعة الاحترافية
→ /prepress

استخدام عام
→ /default
```

---

# 📚 مثال عملي

إذا كان عندك:

```text
C:\PDF\Book.pdf
```

افتح Cmder داخل نفس المجلد واكتب:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=Book_compressed.pdf Book.pdf
```

سيبقى:

```text
Book.pdf
```

وسيُنشأ:

```text
Book_compressed.pdf
```

والملف الأصلي لن يتغير.

---

# 📦 إذا كان اسم الملف فيه مسافات

مثلاً:

```text
My Arabic Book.pdf
```

استخدم علامات الاقتباس:

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="My Arabic Book_compressed.pdf" "My Arabic Book.pdf"
```

---

# ⚠️ ملاحظة مهمة عن Scanned PDFs

إذا كان الـ PDF عبارة عن صفحات صور ممسوحة ضوئيًا:

```text
Scanner
↓
Images
↓
PDF
```

فـ Ghostscript يستطيع تقليل الحجم بشكل كبير.

لكن:

> كلما زاد الضغط، يمكن أن تقل جودة النص والصور.

لذلك ابدأ بـ:

```text
/ebook
```

ثم جرّب `/screen` إذا كان الحجم ما زال كبيرًا.

---

# 🆚 قبل وبعد الضغط

دائمًا قارن:

```text
Original PDF
↓
Compressed PDF
```

وتأكد من:

- جودة النص
    
- وضوح الصور
    
- حجم الملف
    
- فتح جميع الصفحات
    
- عدم وجود مشاكل في الخطوط
    

---

# 🏆 QUICK REFERENCE

## ⭐ أفضل توازن

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

## 📦 أصغر حجم

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

## 🖨️ للطباعة

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

## 🏅 للطباعة الاحترافية

```bash
gswin64c -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/prepress -dNOPAUSE -dQUIET -dBATCH -sOutputFile=compressed.pdf input.pdf
```

---

# 🧠 أهم قاعدة أتذكرها

> **PDF → Ghostscript**
> 
> **أقل حجم → `/screen`**
> 
> **أفضل توازن → `/ebook` ⭐**
> 
> **طباعة → `/printer`**
> 
> **طباعة احترافية → `/prepress`**
> 
> **دائمًا احتفظ بالـ Original**
> 
> **جرّب `/ebook` أولًا**

---
