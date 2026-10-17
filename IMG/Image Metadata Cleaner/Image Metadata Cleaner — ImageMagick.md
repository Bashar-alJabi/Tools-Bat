> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة الصور من CMD / Cmder، ويمكن استخدامها لإزالة الـ Metadata والمعلومات المضمنة داخل ملفات الصور.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

# 🧹 إزالة Metadata

الخيار الأساسي:

```bash
magick input.jpg -strip output.jpg
```

`-strip` يطلب من ImageMagick إزالة الـ profiles والـ comments والبيانات الوصفية المرتبطة بالصورة التي يستطيع ImageMagick إزالتها.

---

# 📍 EXIF و GPS

صور الكاميرات والهواتف قد تحتوي على معلومات مثل:

```text
Camera Make
Camera Model
Date / Time
GPS Latitude
GPS Longitude
Orientation
Lens Information
Exposure Information
```

يمكن إزالة هذه المعلومات باستخدام:

```bash
magick input.jpg -strip output.jpg
```

### ⭐ للاستخدام اليومي

```bash
magick input.jpg -strip output.jpg
```

---

# 📷 معلومات الكاميرا

قد تحتوي الصورة على:

```text
Camera Make
Camera Model
Lens
Focal Length
Exposure
ISO
Flash
Software
```

مثال:

```bash
magick photo.jpg -strip clean.jpg
```

بعد المعالجة، يتم حذف الـ Metadata القابلة للإزالة.

---

# 🕒 معلومات التاريخ والوقت

بعض الصور تحتوي على:

```text
DateTime
DateTimeOriginal
DateTimeDigitized
```

ويمكن إزالة هذه المعلومات باستخدام:

```bash
magick photo.jpg -strip clean.jpg
```

---

# 👤 Author / Copyright / Software

Metadata قد تحتوي أيضًا على:

```text
Author
Copyright
Artist
Software
Creator
Comment
Description
```

مثال:

```bash
magick image.jpg -strip clean.jpg
```

---

# 🖼️ PNG

PNG قد يحتوي على Metadata وchunks إضافية.

```bash
magick input.png -strip output.png
```

---

# 🌐 WebP

```bash
magick input.webp -strip output.webp
```

---

# 🎞️ TIFF

```bash
magick input.tiff -strip output.tiff
```

---

# 📱 صور AI

بعض البرامج والأدوات التي تنشئ أو تعدّل الصور قد تضيف معلومات أو Metadata إلى الملف.

يمكن تنظيف الصورة:

```bash
magick ai-image.jpg -strip clean-image.jpg
```

لكن مهم جدًا:

> إزالة Metadata **لا تضمن** إزالة أي AI label أو AI detection من منصات التواصل الاجتماعي.

منصة مثل Instagram قد تستخدم إشارات أخرى غير Metadata، مثل معلومات المصدر أو أنظمة الكشف الخاصة بها.

لذلك:

```text
Metadata Cleaning
≠
إلغاء AI Detection
```

لكن تنظيف Metadata مفيد للخصوصية وتقليل المعلومات المضمنة داخل الملف.

---

# 🔍 فحص Metadata

ImageMagick يمكنه عرض معلومات الصورة:

```bash
magick identify -verbose image.jpg
```

ابحث عن أقسام مثل:

```text
Properties
Profiles
Artifacts
```

وقد تظهر معلومات مثل:

```text
exif
icc
xmp
comment
```

بعد التنظيف:

```bash
magick identify -verbose clean.jpg
```

يمكن استخدامه للتحقق من المعلومات التي بقيت في الملف.

---

# 🧹 تنظيف صورة

### قبل

```bash
magick identify -verbose input.jpg
```

### تنظيف

```bash
magick input.jpg -strip output.jpg
```

### بعد

```bash
magick identify -verbose output.jpg
```

---

# ⚠️ Metadata Cleaner ≠ Compression

تنظيف Metadata هدفه:

```text
إزالة معلومات إضافية من الملف
```

وليس:

```text
Resize
Compression
Format Conversion
```

مثلاً:

```bash
magick input.jpg -strip output.jpg
```

لا نحدد فيه:

```text
-resize
-quality
```

لأن هذه وظائف منفصلة.

---

# 🔧 أوامر مهمة

### معرفة إصدار ImageMagick

```bash
magick -version
```

### عرض معلومات الصورة

```bash
magick identify -verbose image.jpg
```

### إزالة Metadata

```bash
magick input.jpg -strip output.jpg
```

### إزالة Metadata من PNG

```bash
magick input.png -strip output.png
```

### إزالة Metadata من WebP

```bash
magick input.webp -strip output.webp
```

---

# ⭐ الخلاصة

الخيار الأساسي لتنظيف Metadata:

```bash
-strip
```

والأمر الأساسي:

```bash
magick input.jpg -strip output.jpg
```

يمكن أن يزيل معلومات مثل:

```text
EXIF
GPS
Camera Information
Date / Time
Author
Copyright
Software
Comments
Profiles / Metadata
```

لكن يجب تذكر أن `-strip` يعني **إزالة الـ metadata التي يستطيع ImageMagick إزالتها**، وليس ضمانًا أن كل byte أو كل نوع من المعلومات غير المرئية في كل صيغة سيتم حذفه.

ولفحص النتيجة:

```bash
magick identify -verbose output.jpg
```

---

## 🔒 الهدف من الأداة

**Image Metadata Cleaner** مخصص لتنظيف الصور من المعلومات المضمنة التي لا نريد مشاركتها، خصوصًا:

```text
GPS / Location
Camera Information
Date / Time
Author
Software
Other Metadata
```

بدون أن يكون الهدف تغيير أبعاد الصورة أو ضغطها.
> تنبيه دقة: ImageMagick يعيد ترميز الصورة، وقد يؤثر حذف ICC/EXIF على اللون أو اتجاه العرض. هذه ليست إزالة metadata دون إعادة ضغط JPEG، ولا ضمانًا لبقاء المظهر مطابقًا تمامًا.
