> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لتحويل الصور بين مختلف الصيغ من CMD / Cmder.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

# 🔄 تحويل الصور بين الصيغ

الصيغة الأساسية:

```bash
magick input.jpg output.png
```

ImageMagick يتعرف على صيغة الملف من امتداد `input` و `output`.

مثال:

```bash
magick photo.jpg photo.webp
```

يحوّل:

```text
JPG → WebP
```

---

# 🖼️ JPG

## PNG → JPG

```bash
magick input.png output.jpg
```

## WebP → JPG

```bash
magick input.webp output.jpg
```

## TIFF → JPG

```bash
magick input.tiff output.jpg
```

JPG مناسب أكثر لـ:

- الصور الفوتوغرافية.
    
- الصور التي لا تحتاج Transparency.
    
- الحالات التي يكون فيها حجم الملف مهمًا.
    

---

# 🎯 JPG Quality

عند التحويل إلى JPG يمكن تحديد الجودة باستخدام:

```bash
-quality
```

مثال:

```bash
magick input.png -quality 85 output.jpg
```

### Quality

```text
100 → أعلى جودة / أكبر حجم
90  → جودة ممتازة
85  → ممتازة + حجم مناسب ⭐
80  → جودة جيدة جدًا + حجم أقل
70  → ضغط أكبر
```

### ⭐ للاستخدام اليومي

```bash
magick input.png -quality 85 output.jpg
```

> كلما انخفضت قيمة Quality زاد الضغط وصغر حجم الملف، لكن تقل الجودة البصرية أيضًا.

---

# ⚠️ Transparency عند التحويل إلى JPG

JPG لا يدعم Transparency.

إذا كان الملف الأصلي يحتوي على خلفية شفافة، مثل PNG، يجب تحديد خلفية عند تحويله إلى JPG.

مثال:

```bash
magick input.png -background white -alpha remove -alpha off -quality 85 output.jpg
```

### ماذا يفعل؟

```text
-background white
→ يحدد الخلفية باللون الأبيض

-alpha remove
→ يزيل الشفافية ويستبدلها بالخلفية

-alpha off
→ يعطل Alpha Channel

-quality 85
→ يحدد جودة JPG
```

مثال:

```text
PNG + Transparency
        ↓
      JPG
        ↓
خلفية بيضاء
```

---

# 🖼️ PNG

## JPG → PNG

```bash
magick input.jpg output.png
```

## WebP → PNG

```bash
magick input.webp output.png
```

PNG صيغة **Lossless** ومناسبة عندما تحتاج:

- Transparency
    
- Logos
    
- Graphics
    
- Screenshots
    

### ⭐ ملاحظة

تحويل صورة فوتوغرافية من JPG إلى PNG **لن يعيد الجودة التي فقدت سابقًا بسبب ضغط JPG**.

التحويل يغير الـ Format فقط، ولا يستطيع استرجاع التفاصيل المفقودة.

---

# 🌐 WebP

## JPG → WebP

```bash
magick input.jpg -quality 85 output.webp
```

## PNG → WebP

```bash
magick input.png -quality 85 output.webp
```

WebP مناسب جدًا للويب لأنه يدعم:

- Lossy Compression
    
- Lossless Compression
    
- Transparency
    
- حجم ملفات صغير نسبيًا
    

### ⭐ للاستخدام اليومي

```bash
magick input.jpg -quality 85 output.webp
```

---

# 🟢 WebP Lossless

يمكن إنشاء WebP بدون فقدان:

```bash
magick input.png -define webp:lossless=true output.webp
```

### الفرق

```text
WebP Lossy
→ حجم أصغر
→ فقدان بعض المعلومات

WebP Lossless
→ يحافظ على البيانات
→ حجم أكبر عادةً
```

---

# 🚀 AVIF

## JPG → AVIF

```bash
magick input.jpg -quality 85 output.avif
```

## PNG → AVIF

```bash
magick input.png -quality 85 output.avif
```

AVIF صيغة حديثة توفر Compression قوي وحجمًا صغيرًا.

مناسبة خصوصًا للـ:

- Websites الحديثة.
    
- الصور التي تحتاج حجمًا منخفضًا.
    
- الاستخدامات التي يكون فيها دعم AVIF متوفرًا.
    

---

# 🟣 TIFF

## JPG → TIFF

```bash
magick input.jpg output.tiff
```

## PNG → TIFF

```bash
magick input.png output.tiff
```

TIFF مناسب أكثر لـ:

- Printing
    
- Archiving
    
- Professional Image Workflows
    

---

# 🔵 BMP

## JPG → BMP

```bash
magick input.jpg output.bmp
```

BMP صيغة Bitmap قديمة وبسيطة.

لكن حجم ملفات BMP عادةً أكبر بكثير من:

```text
JPG
WebP
PNG
AVIF
```

---

# 🎞️ GIF

## JPG → GIF

```bash
magick input.jpg output.gif
```

## PNG → GIF

```bash
magick input.png output.gif
```

GIF مناسب أكثر لـ:

- Graphics بسيطة.
    
- صور محدودة الألوان.
    
- Animations.
    

> تحويل صورة واحدة إلى GIF لا يعني إنشاء Animation.

---

# 📊 مقارنة الصيغ

|Format|Compression|Transparency|الاستخدام|
|---|---|---|---|
|JPG|Lossy|❌|Photos|
|PNG|Lossless|✅|Graphics / Logos|
|WebP|Lossy / Lossless|✅|Websites ⭐|
|AVIF|Lossy / Lossless|✅|Modern Web ⭐|
|TIFF|حسب الإعداد|✅|Print / Archive|
|GIF|محدود|✅|Animation / Simple Graphics|
|BMP|ضعيف|محدود|Legacy|

---

# ⭐ أي صيغة أستخدم؟

```text
صور فوتوغرافية
→ JPG

صور Website
→ WebP ⭐

ضغط قوي للويب الحديث
→ AVIF ⭐

Logo / Transparency
→ PNG

Print / Archive
→ TIFF

Animation
→ GIF

توافق مع برامج قديمة
→ BMP
```

---

# 🛠️ معرفة إصدار ImageMagick

```bash
magick -version
```

---

# 🔍 معرفة الصيغ المدعومة

```bash
magick -list format
```

للبحث عن WebP:

```bash
magick -list format | findstr /I "WEBP"
```

للبحث عن AVIF:

```bash
magick -list format | findstr /I "AVIF"
```

---

# ⭐ أوامر جاهزة

## JPG

```bash
magick input.png -quality 85 output.jpg
```

## JPG مع Transparency

```bash
magick input.png -background white -alpha remove -alpha off -quality 85 output.jpg
```

## WebP

```bash
magick input.jpg -quality 85 output.webp
```

## AVIF

```bash
magick input.jpg -quality 85 output.avif
```

## PNG

```bash
magick input.jpg output.png
```

## TIFF

```bash
magick input.jpg output.tiff
```

## BMP

```bash
magick input.jpg output.bmp
```

## GIF

```bash
magick input.jpg output.gif
```

---

# ⭐ الخلاصة

```text
magick input.jpg output.png
→ تحويل الصيغة

-quality 85
→ التحكم بجودة الصيغ Lossy

-background white
→ تحديد خلفية عند تحويل Transparency إلى JPG

-alpha remove
→ إزالة الشفافية

-define webp:lossless=true
→ إنشاء WebP Lossless
```

### أفضل الخيارات للاستخدام اليومي

```text
JPG
→ للصور الفوتوغرافية

WebP
→ للويب ⭐

AVIF
→ ضغط أقوى للويب الحديث ⭐

PNG
→ Transparency / Graphics

TIFF
→ Print / Archive
```