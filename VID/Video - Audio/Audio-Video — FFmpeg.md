> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.

[https://ffmpeg.org/](https://ffmpeg.org/)
[https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
(Download) [https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip)

---

## 📁 الأدوات

هذه الأدوات مخصصة لمعالجة **الصوت الموجود داخل ملفات الفيديو** باستخدام FFmpeg.

```text
🔊 Increase Volume
🎚️ Normalize Audio
🎵 Extract Audio
🎬 Remove Audio
🔀 Merge Audio
🎧 Convert Audio
```

---

# 🔊 Increase Volume — رفع مستوى الصوت

إذا كان صوت الفيديو منخفضًا، يمكن رفع مستوى الصوت باستخدام:

```bash
ffmpeg -i input.mp4 -filter:a "volume=2" -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

### ماذا يفعل؟

- `-i input.mp4` → الفيديو الأصلي.
    
- `-filter:a "volume=2"` → يرفع مستوى الصوت إلى الضعف.
    
- `-c:v copy` → يبقي الفيديو كما هو بدون إعادة ترميز.
    
- `-c:a aac` → يعيد ترميز الصوت إلى AAC.
    
- `-b:a 192k` → جودة الصوت 192 kbps.
    
- `-movflags +faststart` → يحسن تشغيل MP4 عبر الإنترنت.
    
- `output.mp4` → الفيديو الناتج.
    

### 🎯 تغيير مستوى الصوت

يمكن تغيير قيمة `volume`:

```text
volume=1.0  → بدون تغيير
volume=1.5  → زيادة 50%
volume=2.0  → ضعف الصوت ⭐
volume=3.0  → زيادة كبيرة
volume=0.5  → خفض الصوت إلى النصف
```

يمكن أيضًا استخدام **Decibels (dB)** بدلًا من multiplier، وهي طريقة مفيدة للتحكم بمقدار الزيادة بشكل مباشر:

```text
volume=3dB   → زيادة خفيفة
volume=6dB   → زيادة واضحة
volume=9dB   → زيادة قوية
volume=12dB  → زيادة قوية جدًا
volume=-6dB  → خفض الصوت
```

تقريبًا:

```text
+3 dB   ≈ ×1.41
+6 dB   ≈ ×2
+9 dB   ≈ ×2.82
+12 dB  ≈ ×4
```

### مثال

رفع الصوت إلى الضعف باستخدام multiplier:

```bash
ffmpeg -i input.mp4 -filter:a "volume=2" -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

أو رفعه بحوالي **6 dB**:

```bash
ffmpeg -i input.mp4 -filter:a "volume=6dB" -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

⚠️ رفع الصوت بشكل كبير قد يسبب **Clipping / تشويه** إذا كان الصوت الأصلي قريبًا من الحد الأقصى.

---

# 🎚️ Normalize Audio — موازنة مستوى الصوت

إذا كانت مشكلة الفيديو أن مستوى الصوت غير متوازن أو منخفض مقارنةً بمقاطع أخرى، يمكن استخدام:

```bash
ffmpeg -i input.mp4 -af loudnorm -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

### ماذا يفعل؟

- `-af loudnorm` → يطبق Loudness Normalization على الصوت.
    
- `-c:v copy` → الفيديو لا تتم إعادة ترميزه.
    
- `-c:a aac` → تحويل الصوت إلى AAC.
    
- `-b:a 192k` → جودة الصوت 192 kbps.
    
- `-movflags +faststart` → تحسين تشغيل MP4 عبر الإنترنت.
    

### الفرق بين Volume و Normalize

```text
Increase Volume
→ يرفع مستوى الصوت بمقدار محدد.

Normalize Audio
→ يحاول ضبط مستوى الصوت إلى مستوى أكثر اتزانًا.
```

### ⭐ متى أستخدم كل واحد؟

```text
الصوت منخفض بشكل واضح
→ Increase Volume

الصوت غير متوازن / تريد مستوى Loudness موحد
→ Normalize Audio
```

---

# 🎵 Extract Audio — استخراج الصوت من الفيديو

لاستخراج الصوت من الفيديو وتحويله إلى MP3:

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
```

### ماذا يفعل؟

- `-i input.mp4` → الفيديو الأصلي.
    
- `-vn` → تجاهل مسار الفيديو.
    
- `-c:a libmp3lame` → استخدام MP3 Encoder.
    
- `-q:a 2` → جودة MP3 عالية.
    
- `output.mp3` → ملف الصوت الناتج.
    

### 🎯 جودة MP3

مع `libmp3lame` يمكن استخدام:

```text
-q:a 0 → أعلى جودة
-q:a 2 → جودة عالية ⭐
-q:a 4 → جودة جيدة
-q:a 6 → جودة متوسطة
-q:a 9 → أقل جودة
```

كلما **قل الرقم** → جودة أعلى + حجم أكبر.

### مثال

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
```

### ⭐ ملاحظة

هذه العملية تقوم بإنشاء **ملف Audio مستقل** ولا تحتوي النتيجة على الفيديو.

```text
Video.mp4
    ↓
Audio.mp3
```

---

# 🎬 Remove Audio — إزالة الصوت من الفيديو

لحذف الصوت من الفيديو مع إبقاء الصورة:

```bash
ffmpeg -i input.mp4 -an -c:v copy output.mp4
```

### ماذا يفعل؟

- `-i input.mp4` → الفيديو الأصلي.
    
- `-an` → إزالة جميع مسارات الصوت.
    
- `-c:v copy` → نسخ الفيديو بدون إعادة ترميز.
    

### ⭐ الميزة

هذه العملية سريعة جدًا لأن الفيديو لا تتم إعادة معالجته.

```text
Video + Audio
      ↓
Video فقط
```

---

# 🔀 Merge Audio — دمج صوت مع فيديو

إذا كان لديك:

```text
Video.mp4
Music.mp3
```

يمكن وضع الصوت الجديد داخل الفيديو:

```bash
ffmpeg -i Video.mp4 -i Music.mp3 -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -movflags +faststart -shortest output.mp4
```

### ماذا يفعل؟

- `-i Video.mp4` → الفيديو.
    
- `-i Music.mp3` → ملف الصوت.
    
- `-map 0:v` → استخدام الفيديو من الملف الأول.
    
- `-map 1:a` → استخدام الصوت من الملف الثاني.
    
- `-c:v copy` → لا يعيد ترميز الفيديو.
    
- `-c:a aac` → تحويل الصوت إلى AAC.
    
- `-b:a 192k` → جودة الصوت 192 kbps.
    
- `-shortest` → إنهاء الفيديو عندما ينتهي أقصر Stream.
    
- `-movflags +faststart` → تحسين تشغيل MP4 عبر الإنترنت.
    

### ⚠️ ماذا يحدث للصوت الأصلي؟

في هذا الأمر:

```bash
-map 0:v
-map 1:a
```

يتم استخدام **الصوت الجديد فقط**.

أي أن الصوت الأصلي للفيديو لا يتم الاحتفاظ به.

```text
Video
├── Video
└── Original Audio ❌

Music
└── New Audio ✅

        ↓

Output
├── Video
└── New Audio
```

### ⭐ إذا أردت دمج الصوتين معًا

إذا أردت الاحتفاظ بالصوت الأصلي وإضافة موسيقى فوقه، نستخدم Audio Mixing مثل:

```bash
ffmpeg -i Video.mp4 -i Music.mp3 -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2" -map 0:v -map 0:a? -map 1:a? -c:v copy -c:a aac -b:a 192k output.mp4
```

لكن هذه الطريقة تحتاج ضبط مستوى الصوت لكل مسار حتى لا تصبح النتيجة عالية أو مشوشة.

---

# 🎧 Convert Audio — تحويل Audio داخل الفيديو

إذا كان الفيديو يحتوي على Audio Codec غير مناسب وتريد تحويل الصوت إلى AAC مع إبقاء الفيديو:

```bash
ffmpeg -i input.mp4 -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

### ماذا يفعل؟

- `-c:v copy` → الفيديو يبقى كما هو.
    
- `-c:a aac` → تحويل الصوت إلى AAC.
    
- `-b:a 192k` → جودة الصوت 192 kbps.
    
- `-movflags +faststart` → تحسين تشغيل MP4 عبر الإنترنت.
    

### ⭐ مثال

```text
Video
│
├── Video H.264
└── Audio Opus

        ↓

Convert Audio

        ↓

Video
│
├── Video H.264  ← بدون تغيير
└── Audio AAC    ← تم تحويله
```

### متى أستخدمه؟

- عندما يكون الـAudio Codec غير متوافق مع جهاز أو موقع.
    
- عندما تريد Audio AAC داخل MP4.
    
- عندما تريد تغيير Codec الصوت بدون إعادة ترميز الفيديو.


---

# 🧠 أهم الخيارات بسرعة

|الخيار|الوظيفة|
|---|---|
|`-filter:a "volume=2"`|رفع/خفض مستوى الصوت|
|`-af loudnorm`|موازنة مستوى الصوت|
|`-vn`|إزالة الفيديو / استخراج الصوت|
|`-an`|إزالة الصوت|
|`-c:v copy`|نسخ الفيديو بدون إعادة ترميز|
|`-c:a aac`|تحويل الصوت إلى AAC|
|`-c:a libmp3lame`|تحويل الصوت إلى MP3|
|`-b:a 192k`|تحديد Bitrate للصوت|
|`-q:a 2`|جودة MP3 عالية|
|`-map 0:v`|اختيار الفيديو من الإدخال الأول|
|`-map 1:a`|اختيار الصوت من الإدخال الثاني|
|`-shortest`|إنهاء الناتج عند انتهاء أقصر Stream|
|`-movflags +faststart`|تحسين تشغيل MP4 عبر الإنترنت|

---

# 🏆 QUICK REFERENCE

## 🔊 رفع الصوت

```bash
ffmpeg -i input.mp4 -filter:a "volume=2" -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

## 🎚️ Normalize

```bash
ffmpeg -i input.mp4 -af loudnorm -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

## 🎵 استخراج الصوت

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
```

## 🎬 إزالة الصوت

```bash
ffmpeg -i input.mp4 -an -c:v copy output.mp4
```

## 🔀 استبدال الصوت

```bash
ffmpeg -i Video.mp4 -i Audio.mp3 -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k -movflags +faststart -shortest output.mp4
```

## 🎧 تحويل Audio إلى AAC

```bash
ffmpeg -i input.mp4 -c:v copy -c:a aac -b:a 192k -movflags +faststart output.mp4
```

---

# 🧠 القاعدة السريعة

```text
الصوت منخفض
→ Increase Volume

الصوت غير متوازن
→ Normalize Audio

تريد الصوت كملف مستقل
→ Extract Audio

تريد فيديو بدون صوت
→ Remove Audio

تريد استبدال صوت الفيديو
→ Merge Audio

تريد تغيير Audio Codec
→ Convert Audio

تريد تشغيل MP4 بشكل أفضل عبر الإنترنت
→ -movflags +faststart
```