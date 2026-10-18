> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة وتغيير حجم الصور من CMD / Cmder، ومن أهم استخداماتها تغيير أبعاد الصورة مع الحفاظ على الـ Aspect Ratio.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

# 📐 تغيير حجم الصورة

الصيغة الأساسية:

```bash
magick input.jpg -resize 1600x1600 output.jpg
```

ImageMagick يحافظ تلقائيًا على **Aspect Ratio** عند استخدام `-resize` بهذه الطريقة.

مثال:

```bash
magick input.jpg -resize 1600x1600 output.jpg
```

إذا كانت الصورة:

```text
4000 × 3000
```

تصبح:

```text
1600 × 1200
```

وليس:

```text
1600 × 1600
```

لأن ImageMagick يحافظ على النسبة الأصلية للصورة.

---

# 🔒 الحفاظ على Aspect Ratio

```bash
magick input.jpg -resize 1600x1600 output.jpg
```

هذا لا يجبر الصورة على أن تصبح 1600×1600.

بل يعتبر:

```text
1600 px → أقصى Width
1600 px → أقصى Height
```

ويحسب البعد الآخر تلقائيًا.

### أمثلة

```text
4000 × 3000
→ 1600 × 1200
```

```text
3000 × 4000
→ 1200 × 1600
```

```text
2000 × 2000
→ 1600 × 1600
```

---

# 🚫 منع تكبير الصور الصغيرة

يمكن إضافة:

```text
>
```

بعد أبعاد الـ Resize:

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

هذا يعني:

> Resize فقط إذا كانت الصورة أكبر من الحجم المطلوب.

مثلاً:

```text
4000 × 3000
→ 1600 × 1200
```

لكن:

```text
1000 × 800
→ 1000 × 800
```

لن يتم تكبيرها إلى:

```text
1600 × 1280
```

### ⭐ للاستخدام اليومي

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

مفيد عندما نريد تصغير مجموعة صور بدون أن نخسر جودة الصور الصغيرة بسبب Upscaling.

---

# ↔️ تحديد Width فقط

```bash
magick input.jpg -resize 1600x output.jpg
```

هنا نحدد:

```text
Width = 1600 px
```

ويتم حساب الـ Height تلقائيًا للحفاظ على Aspect Ratio.

مثال:

```text
4000 × 3000
→ 1600 × 1200
```

---

# ↕️ تحديد Height فقط

```bash
magick input.jpg -resize x1600 output.jpg
```

هنا نحدد:

```text
Height = 1600 px
```

ويتم حساب الـ Width تلقائيًا.

مثال:

```text
3000 × 4000
→ 1200 × 1600
```

---

# 📦 Max Dimensions

عندما نريد أن تكون الصورة ضمن حدود معينة:

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

يعني:

```text
Maximum Width  = 1600
Maximum Height = 1600
```

مع:

```text
Aspect Ratio = محفوظ
Upscaling    = ممنوع
```

وهذا مناسب جدًا لتحضير الصور للويب أو للرفع إلى المواقع.

---

# 📊 أمثلة سريعة

### 1920 × 1080

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

النتيجة:

```text
1600 × 900
```

### 4000 × 3000

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

النتيجة:

```text
1600 × 1200
```

### 3000 × 4000

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

النتيجة:

```text
1200 × 1600
```

### 1000 × 700

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

النتيجة:

```text
1000 × 700
```

لأن الصورة أصلًا أصغر من الحد المطلوب.

---

# ⚠️ Resize ≠ Crop

`-resize` يحافظ على الصورة كاملة:

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

لذلك إذا كانت الصورة:

```text
4000 × 2000
```

فالنتيجة ستكون:

```text
1600 × 800
```

وليس:

```text
1600 × 1600
```

إذا أردنا صورة فعلية بمقاس مربع مع قص الأطراف، فهذا يعتبر **Crop** وليس Resize.

---

# 🔧 أوامر مهمة

### معرفة إصدار ImageMagick

```bash
magick -version
```

### Resize مع الحفاظ على النسبة

```bash
magick input.jpg -resize 1600x1600 output.jpg
```

### Resize مع منع Upscaling

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

### Width فقط

```bash
magick input.jpg -resize 1600x output.jpg
```

### Height فقط

```bash
magick input.jpg -resize x1600 output.jpg
```

---

# ⭐ الخلاصة

لـ **Image Resize** مع الحفاظ على Aspect Ratio:

```bash
magick input.jpg -resize "1600x1600>" output.jpg
```

حيث:

```text
1600 × 1600 → Maximum Dimensions
>           → لا تكبير للصور الصغيرة
Aspect Ratio → محفوظ تلقائيًا
```

هذه هي الصيغة المناسبة عندما يكون الهدف هو **تصغير الصور إلى حد أقصى محدد بدون تشويه أبعادها أو تكبير الصور الصغيرة**.