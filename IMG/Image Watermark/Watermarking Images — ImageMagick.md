> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لمعالجة وضغط الصور من CMD / Cmder.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---

يُستخدم ImageMagick لإضافة **علامة مائية نصية أو صورة/شعار** إلى الصور، مع التحكم بحجمها، شفافيتها، دورانها وموقعها.

الطريقة الأفضل هي إنشاء العلامة المائية كطبقة شفافة مستقلة، ثم دمجها مع الصورة الأصلية باستخدام `-composite`.

---

## 1. الفكرة الأساسية

تسلسل العمل:

```text
الصورة الأصلية
      ↓
إنشاء طبقة العلامة المائية
      ↓
تعديل الشفافية
      ↓
تدوير العلامة عند الحاجة
      ↓
تحديد الموقع
      ↓
دمجها مع الصورة
      ↓
الصورة النهائية
```

استخدام طبقة منفصلة يجعل التحكم بالعلامة المائية أسهل، خصوصًا عند الحاجة إلى تغيير الحجم أو الشفافية أو الدوران.

---

# 2. العلامة المائية النصية

يمكن إنشاء النص كصورة PNG بخلفية شفافة باستخدام `label:`:

```bash
magick ^
    -background none ^
    -fill white ^
    -pointsize 64 ^
    -gravity center ^
    label:"Copyright 2026" ^
    -trim ^
    +repage ^
    watermark.png
```

### أهم الخيارات

`-background none`

يجعل خلفية العلامة المائية شفافة.

`-fill white`

يحدد لون النص.

`-pointsize 64`

يحدد حجم الخط.

`label:"..."`

ينشئ صورة تحتوي على النص.

`-trim`

يزيل المساحات الشفافة الزائدة حول النص.

`+repage`

يعيد ضبط الـVirtual Canvas بعد عملية القص.

---

# 3. التحكم بشفافية النص

يمكن التحكم بالشفافية عن طريق تعديل قناة الـAlpha:

```bash
magick watermark.png ^
    -alpha set ^
    -channel A ^
    -evaluate multiply 0.60 ^
    +channel ^
    watermark.png
```

أمثلة:

```text
0.20 → 20%
0.40 → 40%
0.60 → 60%
0.80 → 80%
1.00 → 100%
```

الجزء الأساسي هو:

```bash
-channel A
-evaluate multiply 0.60
+channel
```

`A` تعني قناة **Alpha**.

بهذه الطريقة يتم تخفيض شفافية العلامة المائية مع الحفاظ على الشفافية الأصلية الموجودة فيها.

---

# 4. العلامة المائية باستخدام Logo

يمكن استخدام صورة أو شعار كعلامة مائية:

```bash
magick logo.png ^
    -resize "500x" ^
    -alpha set ^
    -channel A ^
    -evaluate multiply 0.60 ^
    +channel ^
    watermark.png
```

إذا كان الـLogo يحتوي أصلًا على خلفية شفافة، فإن تعديل قناة الـAlpha يحافظ على هذه الشفافية ويخفض وضوح الشعار بشكل متناسق.

---

# 5. تغيير حجم الـLogo حسب عرض الصورة

يمكن جعل حجم الـLogo نسبة مئوية من عرض الصورة الأصلية.

مثلًا:

```text
عرض الصورة = 4000px
حجم الـLogo = 25%
```

الحساب:

```text
4000 × 25 ÷ 100 = 1000px
```

ثم:

```bash
magick logo.png -resize "1000x" watermark.png
```

بهذه الطريقة يصبح حجم الـLogo متناسبًا مع دقة الصورة، بدل استخدام حجم ثابت لجميع الصور.

---

# 6. تدوير العلامة المائية

يمكن تدوير طبقة العلامة المائية قبل دمجها:

```bash
magick watermark.png ^
    -background none ^
    -rotate 8 ^
    +repage ^
    watermark_rotated.png
```

ميلان لليسار:

```bash
-rotate -8
```

ميلان لليمين:

```bash
-rotate 8
```

بدون دوران:

```text
0°
```

وميلان بسيط مثل:

```text
-8°
0°
+8°
```

يكون مناسبًا عندما نريد تأثيرًا خفيفًا بدون جعل العلامة المائية مزعجة.

`-background none` مهم للحفاظ على الخلفية الشفافة أثناء الدوران.

`+repage` يعيد ضبط الـVirtual Canvas بعد الدوران.

---

# 7. تحديد موقع العلامة المائية

يستخدم ImageMagick الخيار `-gravity` لتحديد مكان العلامة المائية.

المواقع الأساسية:

|الموقع|Gravity|
|---|---|
|أعلى يسار|`northwest`|
|أعلى وسط|`north`|
|أعلى يمين|`northeast`|
|وسط يسار|`west`|
|الوسط|`center`|
|وسط يمين|`east`|
|أسفل يسار|`southwest`|
|أسفل وسط|`south`|
|أسفل يمين|`southeast`|

مثال:

```bash
magick input.jpg watermark.png ^
    -gravity southeast ^
    -geometry +30+30 ^
    -composite ^
    output.jpg
```

---

# 8. الإزاحة عن الحواف

يمكن استخدام `-geometry` لإضافة مسافة بين العلامة المائية وحواف الصورة.

مثال:

```bash
-geometry +30+30
```

مع:

```bash
-gravity southeast
```

يتم وضع العلامة المائية بالقرب من الزاوية السفلية اليمنى مع ترك مسافة عن الحواف.

---

# 9. دمج العلامة المائية

الخيار المسؤول عن دمج طبقة العلامة المائية مع الصورة هو:

```bash
-composite
```

مثال بسيط:

```bash
magick input.jpg watermark.png ^
    -gravity center ^
    -composite ^
    output.jpg
```

المبدأ:

```text
الصورة الأصلية
      +
طبقة العلامة المائية
      ↓
   -composite
      ↓
الصورة النهائية
```

---

# 10. إضافة أكثر من علامة مائية

يمكن استخدام نفس طبقة العلامة المائية عدة مرات في أماكن مختلفة.

مثال:

```bash
magick input.png watermark.png ^
    -gravity northwest ^
    -geometry +30+30 ^
    -composite ^
    first.png
```

ثم استخدام الناتج لإضافة علامة أخرى:

```bash
magick first.png watermark.png ^
    -gravity southeast ^
    -geometry +30+30 ^
    -composite ^
    output.png
```

يمكن بذلك وضع نفس العلامة المائية في عدة أماكن، مثل:

```text
أعلى يسار      أعلى وسط      أعلى يمين

وسط يسار       الوسط         وسط يمين

أسفل يسار      أسفل وسط      أسفل يمين
```

أي يمكن استخدام **حتى 9 مواقع مختلفة**.

لا تحتاج العلامة المائية إلى إعادة إنشائها لكل موقع؛ يمكن إعادة استخدام نفس الـWatermark Layer.

---

# 11. الحفاظ على جودة الصورة أثناء المعالجة

عند تطبيق عدة علامات مائية، من الأفضل استخدام صيغة غير فقدية مثل PNG كصورة عمل مؤقتة:

```text
الصورة الأصلية
      ↓
PNG Working Image
      ↓
Watermark 1
      ↓
Watermark 2
      ↓
Watermark 3
      ↓
...
      ↓
الصورة النهائية
```

بهذا نتجنب إعادة ضغط JPEG بعد كل عملية دمج.

يتم حفظ الصورة بالصيغة النهائية المطلوبة مرة واحدة بعد انتهاء جميع عمليات العلامة المائية.

---

# 12. مثال كامل — Text Watermark

إنشاء طبقة النص:

```bash
magick ^
    -background none ^
    -fill white ^
    -pointsize 64 ^
    -gravity center ^
    label:"Copyright 2026" ^
    -trim ^
    +repage ^
    watermark.png
```

تطبيق شفافية 60%:

```bash
magick watermark.png ^
    -alpha set ^
    -channel A ^
    -evaluate multiply 0.60 ^
    +channel ^
    watermark.png
```

تدويرها:

```bash
magick watermark.png ^
    -background none ^
    -rotate 8 ^
    +repage ^
    watermark_rotated.png
```

دمجها:

```bash
magick input.jpg watermark_rotated.png ^
    -gravity southeast ^
    -geometry +30+30 ^
    -composite ^
    output.jpg
```

---

# 13. مثال كامل — Logo Watermark

تغيير حجم الـLogo وتطبيق الشفافية:

```bash
magick logo.png ^
    -resize "1000x" ^
    -alpha set ^
    -channel A ^
    -evaluate multiply 0.60 ^
    +channel ^
    watermark.png
```

تدويره:

```bash
magick watermark.png ^
    -background none ^
    -rotate -8 ^
    +repage ^
    watermark_rotated.png
```

دمجه مع الصورة:

```bash
magick input.jpg watermark_rotated.png ^
    -gravity center ^
    -composite ^
    output.jpg
```

---

# أهم الأوامر

### الخلفية الشفافة

```text
-background none
```

إنشاء خلفية شفافة.

### إنشاء النص كصورة

```text
label:"Text"
```

تحويل النص إلى صورة يمكن التعامل معها كطبقة.

### تفعيل قناة Alpha

```text
-alpha set
```

تفعيل التعامل مع الشفافية.

### تحديد قناة Alpha

```text
-channel A
```

اختيار قناة الشفافية.

### تعديل الشفافية

```text
-evaluate multiply 0.60
```

جعل الـAlpha بنسبة 60%.

### العودة للوضع الطبيعي للقنوات

```text
+channel
```

إيقاف استهداف قناة معينة.

### تدوير العلامة المائية

```text
-rotate 8
```

تدوير الطبقة.

### تحديد مكانها

```text
-gravity southeast
```

اختيار موقع العلامة المائية.

### إضافة مسافة عن الحواف

```text
-geometry +30+30
```

تحديد الإزاحة عن الحواف.

### دمج الطبقة

```text
-composite
```

دمج العلامة المائية مع الصورة.

### إعادة ضبط الـVirtual Canvas

```text
+repage
```

مفيد بعد `-trim` و`-rotate` وغيرها من العمليات التي تغير أبعاد الـCanvas.