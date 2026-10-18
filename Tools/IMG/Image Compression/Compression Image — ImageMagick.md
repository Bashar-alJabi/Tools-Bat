> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة وضغط الصور من CMD / Cmder.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

# 🖼️ ضغط JPG

```bash
magick input.jpg -quality 85 output.jpg
```

## Quality

```text
100 → أعلى جودة / أكبر حجم
90  → جودة ممتازة
85  → ممتاز جدًا + حجم مناسب ⭐
80  → جودة جيدة جدًا + حجم أقل
70  → ضغط أكبر
```

### ⭐ للاستخدام اليومي

```bash
magick input.jpg -quality 85 output.jpg
```

> `-quality` يؤثر على جودة وحجم الصور التي تستخدم ضغطًا Lossy مثل JPG.

---

# 🌐 ضغط WebP

```bash
magick input.webp -quality 85 output.webp
```

### Quality

```text
90 → جودة عالية
85 → ممتاز جدًا ⭐
80 → حجم أقل
70 → ضغط أكبر
```

WebP يدعم ضغطًا Lossy وLossless.

### WebP Lossless

```bash
magick input.png -define webp:lossless=true output.webp
```

هنا لا يتم فقدان معلومات الصورة بسبب الضغط Lossy.

---

# 🖼️ ضغط AVIF

```bash
magick input.avif -quality 85 output.avif
```

ويمكن استخدام Quality أقل للحصول على حجم أصغر.

```text
90 → جودة عالية
85 → ممتاز ⭐
80 → حجم أقل
70 → ضغط أكبر
```

---

# 🖼️ ضغط PNG

PNG يستخدم ضغطًا **Lossless**، لذلك `-quality` ليس الطريقة الأساسية لضغط PNG مثل JPG.

يمكن استخدام:

```bash
magick input.png -define png:compression-level=9 output.png
```

### Compression Level

```text
0 → أقل ضغط
9 → أعلى مستوى ضغط
```

هذا لا يعني فقدان جودة الصورة.

### إزالة Metadata

```bash
magick input.png -strip -define png:compression-level=9 output.png
```

`-strip` يحذف Metadata غير الضرورية مثل EXIF، مما قد يقلل حجم الملف أيضًا.

---

# 📦 ضغط TIFF

TIFF يمكن استخدام ضغط Lossless مثل ZIP:

```bash
magick input.tiff -compress Zip output.tiff
```

ولإزالة Metadata أيضًا:

```bash
magick input.tiff -strip -compress Zip output.tiff
```

---

# 🧹 إزالة Metadata

```bash
magick input.jpg -strip -quality 85 output.jpg
```

`-strip` يزيل البيانات الوصفية غير الضرورية مثل بعض معلومات EXIF وMetadata.

هذا قد يقلل حجم الملف بدون تغيير أبعاد الصورة.

---

# ⚠️ Compression ≠ Resize

الـ Compression يركز على **تقليل حجم الملف**.

مثلاً:

```bash
magick input.jpg -quality 85 output.jpg
```

يمكن أن تبقى أبعاد الصورة:

```text
4000 × 3000
```

بينما ينخفض حجم الملف.

أما:

```bash
magick input.jpg -resize "2000x2000>" output.jpg
```

فهذا **Resize** ويغيّر أبعاد الصورة.

ويمكن الجمع بين الاثنين، لكنهما وظيفتان مختلفتان.

---

# ⭐ أفضل أوامر للاستخدام اليومي

### JPG

```bash
magick input.jpg -strip -quality 85 output.jpg
```

### WebP

```bash
magick input.webp -strip -quality 85 output.webp
```

### AVIF

```bash
magick input.avif -strip -quality 85 output.avif
```

### PNG

```bash
magick input.png -strip -define png:compression-level=9 output.png
```

### TIFF

```bash
magick input.tiff -strip -compress Zip output.tiff
```

---

# 📊 Lossy vs Lossless

## Lossy

يتم حذف بعض المعلومات للحصول على حجم أصغر.

أمثلة:

```text
JPG
WebP Lossy
AVIF Lossy
```

الميزة:

```text
حجم أصغر
```

مقابل:

```text
فقدان بسيط في الجودة حسب مستوى الضغط
```

---

## Lossless

يحافظ على معلومات الصورة بدون فقدان بسبب الضغط.

أمثلة:

```text
PNG
TIFF + ZIP
WebP Lossless
```

الميزة:

```text
لا يوجد فقدان للصورة بسبب الضغط
```

لكن الحجم غالبًا يكون أكبر من Lossy.

---

# 🎯 اختيار Quality

```text
90 → عندما تكون الجودة أولوية
85 → توازن ممتاز ⭐
80 → حجم أصغر مع جودة جيدة جدًا
70 → ضغط أكبر
```

بالنسبة للاستخدام اليومي:

```bash
-quality 85
```

نقطة بداية جيدة، ثم يتم تعديلها حسب نوع الصورة والاستخدام.

---

# 🔧 أوامر مهمة

### معرفة إصدار ImageMagick

```bash
magick -version
```

### معرفة الصيغ المدعومة

```bash
magick -list format
```

### ضغط JPG

```bash
magick input.jpg -strip -quality 85 output.jpg
```

### ضغط PNG

```bash
magick input.png -strip -define png:compression-level=9 output.png
```

### ضغط WebP

```bash
magick input.webp -strip -quality 85 output.webp
```

### ضغط AVIF

```bash
magick input.avif -strip -quality 85 output.avif
```

### ضغط TIFF

```bash
magick input.tiff -strip -compress Zip output.tiff
```

---

# ⭐ الخلاصة

**Compression** هدفه الأساسي:

```text
تقليل File Size
```

بدون أن يكون تغيير أبعاد الصورة جزءًا من العملية.

أهم الخيارات:

```text
-quality
→ جودة/حجم Lossy formats

-define png:compression-level=9
→ ضغط PNG

-compress Zip
→ ضغط TIFF

-strip
→ إزالة Metadata غير الضرورية
```

أما تغيير أبعاد الصورة فهو وظيفة منفصلة:

```bash
-resize
```

ولا يجب الخلط بين **Image Resize** و **Image Compression**.