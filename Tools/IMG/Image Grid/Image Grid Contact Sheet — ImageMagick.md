> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة الصور من CMD / Cmder، ويمكن استخدامها لإنشاء **Contact Sheet** تجمع عدة صور في صورة واحدة على شكل Grid.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

# 🖼️ ما هو Contact Sheet؟

Contact Sheet هو عبارة عن صورة واحدة تحتوي على مجموعة من الصور مرتبة ضمن Grid.

مثلاً:

```text
┌─────────┬─────────┬─────────┐
│ Image 1 │ Image 2 │ Image 3 │
├─────────┼─────────┼─────────┤
│ Image 4 │ Image 5 │ Image 6 │
├─────────┼─────────┼─────────┤
│ Image 7 │ Image 8 │ Image 9 │
└─────────┴─────────┴─────────┘
```

مفيد لمعاينة عدد كبير من الصور بسرعة أو إنشاء Preview / Thumbnail Sheet.

---

# 📐 إنشاء Contact Sheet

الأداة الأساسية في ImageMagick هي:

```bash
magick montage image1.jpg image2.jpg image3.jpg output.png
```

لكن عند وجود عدد كبير من الصور، يمكن استخدام:

```bash
magick montage *.jpg output.png
```

---

# 🔲 تحديد عدد الأعمدة

باستخدام:

```bash
-tile
```

مثلاً:

```bash
magick montage *.jpg -tile 4x output.png
```

يعني:

```text
4 أعمدة
عدد الصفوف حسب عدد الصور
```

مثال:

```text
┌─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │
├─────┼─────┼─────┼─────┤
│  5  │  6  │  7  │  8  │
├─────┼─────┼─────┼─────┤
│  9  │ 10  │ 11  │ 12  │
└─────┴─────┴─────┴─────┘
```

---

# 📏 تحديد حجم الصور

يمكن تحديد حجم الـThumbnail باستخدام:

```bash
-thumbnail 300x300
```

مثال:

```bash
magick montage *.jpg -thumbnail 300x300 -tile 4x output.png
```

`300x300` هنا يمثل **أقصى مساحة للـThumbnail**.

لا يعني أن كل صورة سيتم تشويهها إلى 300×300.

مثلاً:

```text
400 × 300
```

تصبح تقريبًا:

```text
300 × 225
```

بينما:

```text
300 × 400
```

تصبح:

```text
225 × 300
```

وبالتالي يتم الحفاظ على **Aspect Ratio**.

---

# ↔️ المسافات بين الصور

يمكن استخدام:

```bash
-geometry
```

مثلاً:

```bash
-geometry 300x300+20+20
```

يعني:

```text
300x300 → مساحة الصورة
+20     → Horizontal spacing
+20     → Vertical spacing
```

مثال كامل:

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+20 ^
    output.png
```

---

# 🏷️ إضافة أسماء الملفات

يمكن إضافة Label لكل صورة:

```bash
-label "%f"
```

`%f` تعني اسم الملف.

مثلاً:

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+40 ^
    -label "%f" ^
    output.png
```

إذا كان عندك:

```text
teacher-01.jpg
teacher-02.jpg
teacher-03.jpg
```

ستظهر أسماء الملفات تحت الصور.

---

# 🎨 الخلفية والنص

يمكن تحديد لون الخلفية:

```bash
-background white
```

ولون النص:

```bash
-fill black
```

وحجم الخط:

```bash
-pointsize 16
```

مثال:

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+45 ^
    -background white ^
    -fill black ^
    -pointsize 16 ^
    -label "%f" ^
    output.png
```

---

# ⭐ أمر عملي كامل

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+45 ^
    -background white ^
    -fill black ^
    -pointsize 16 ^
    -label "%f" ^
    contact-sheet.png
```

هذا يقوم بـ:

```text
*.jpg
   ↓
Thumbnail 300×300
   ↓
4 Columns
   ↓
مسافات بين الصور
   ↓
اسم الملف تحت كل صورة
   ↓
خلفية بيضاء
   ↓
contact-sheet.png
```

---

# 📂 دعم صيغ مختلفة

يمكن لـ ImageMagick التعامل مع العديد من صيغ الصور، مثل:

```text
JPG
JPEG
PNG
WebP
TIFF
BMP
GIF
AVIF
```

لكن استخدام:

```bash
*.jpg
```

سيجمع ملفات JPG فقط.

عند الحاجة إلى مجموعة تحتوي على صيغ مختلفة، يجب تمرير الملفات المختلفة إلى `montage` بدل الاعتماد على wildcard واحد.

---

# 🔧 أوامر مهمة

### Contact Sheet من عدة صور

```bash
magick montage image1.jpg image2.jpg image3.jpg output.png
```

### 4 أعمدة

```bash
magick montage *.jpg -tile 4x output.png
```

### Thumbnail

```bash
magick montage *.jpg -thumbnail 300x300 output.png
```

### إضافة أسماء الملفات

```bash
magick montage *.jpg -label "%f" output.png
```

### Contact Sheet كاملة

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+40 ^
    -background white ^
    -fill black ^
    -pointsize 16 ^
    -label "%f" ^
    contact-sheet.png
```

---

# ⭐ الخلاصة

الأداة الأساسية:

```bash
magick montage
```

أهم الخيارات:

```text
-tile
→ عدد الأعمدة / ترتيب الـGrid

-thumbnail
→ حجم معاينة الصور

-geometry
→ حجم الخلايا والمسافات

-label
→ اسم الملف

-background
→ خلفية الـContact Sheet

-fill
→ لون النص

-pointsize
→ حجم النص
```

أمر عملي:

```bash
magick montage *.jpg ^
    -thumbnail 300x300 ^
    -tile 4x ^
    -geometry 300x300+20+40 ^
    -label "%f" ^
    contact-sheet.png
```

النتيجة: **صورة واحدة تحتوي Grid من الصور مع أسماء الملفات، مع الحفاظ على Aspect Ratio للصور داخل الـGrid.**