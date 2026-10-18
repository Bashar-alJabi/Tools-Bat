> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة وضغط الصور من CMD / Cmder.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe

## ما هو Image Crop؟

الـ **Crop** يعني قص جزء من الصورة وإزالة الأجزاء الزائدة، مع الحفاظ على المحتوى الأساسي الموجود داخل المنطقة المحددة.

في ImageMagick يتم تنفيذ القص باستخدام:

```bash
-crop
```

---

## 🎯 القص بنسبة Aspect Ratio

يمكن استخدام `-crop` لقص الصورة حسب نسبة معينة.

مثلاً:

```bash
magick input.jpg -gravity center -crop 1:1! +repage output.jpg
```

هذا يقص الصورة إلى نسبة:

```text
1:1
```

أي صورة مربعة.

أمثلة أخرى:

```bash
-crop 4:5!
```

```bash
-crop 16:9!
```

```bash
-crop 9:16!
```

### النسب الشائعة

|Ratio|الاستخدام|
|---|---|
|`1:1`|Square|
|`4:5`|Portrait|
|`16:9`|Landscape|
|`9:16`|Vertical|

---

## 📍 تحديد مكان القص

يمكن استخدام:

```bash
-gravity
```

لتحديد المنطقة التي يعتمد عليها ImageMagick عند تنفيذ القص.

للقص من المنتصف:

```bash
-gravity center
```

مثال:

```bash
magick input.jpg ^
    -gravity center ^
    -crop 4:5! ^
    +repage ^
    output.jpg
```

هذا يجعل ImageMagick يأخذ الجزء **المركزي** من الصورة ويحذف الزوائد من الأطراف.

---

## ❗ علامة `!`

عند استخدام:

```bash
-crop 4:5!
```

فالـ `!` تخبر ImageMagick أن النسبة المحددة يجب تطبيقها **بالضبط**.

مثلاً:

```bash
-crop 1:1!
```

يعني أن الناتج يجب أن يكون بنسبة `1:1`.

---

## 🧹 +repage

بعد استخدام `-crop` من الأفضل استخدام:

```bash
+repage
```

لإزالة معلومات الـpage/canvas القديمة الناتجة عن عملية القص.

مثال:

```bash
magick input.jpg ^
    -gravity center ^
    -crop 16:9! ^
    +repage ^
    output.jpg
```

---

## 🖼️ أمثلة عملية

### Square — 1:1

```bash
magick photo.jpg -gravity center -crop 1:1! +repage square.jpg
```

### Portrait — 4:5

```bash
magick photo.jpg -gravity center -crop 4:5! +repage portrait.jpg
```

### Landscape — 16:9

```bash
magick photo.jpg -gravity center -crop 16:9! +repage landscape.jpg
```

### Vertical — 9:16

```bash
magick photo.jpg -gravity center -crop 9:16! +repage vertical.jpg
```

---

## 📐 كيف يعمل Center Crop؟

إذا كانت الصورة:

```text
4000 × 3000
```

واخترنا:

```text
1:1
```

سيتم أخذ منطقة مربعة من منتصف الصورة، تقريباً:

```text
3000 × 3000
```

ويتم حذف الجزء الزائد من اليمين واليسار.

أما إذا اخترنا:

```text
4:5
```

فسيتم قص الصورة إلى منطقة Portrait بنسبة `4:5`.

---

## 🔧 أوامر مفيدة

معرفة إصدار ImageMagick:

```bash
magick -version
```

عرض معلومات الصورة:

```bash
magick identify image.jpg
```

عرض أبعاد الصورة:

```bash
magick identify -format "%wx%h" image.jpg
```

---

## 📌 الخلاصة

أهم أوامر Crop:

```bash
-crop
```

لتحديد عملية القص.

```bash
-gravity center
```

لجعل القص من المنتصف.

```bash
+repage
```

لتنظيف معلومات الـcanvas بعد القص.

مثال أساسي:

```bash
magick input.jpg -gravity center -crop 4:5! +repage output.jpg
```