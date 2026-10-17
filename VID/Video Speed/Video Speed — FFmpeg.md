> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.


> تغيير سرعة الفيديو مع تعديل سرعة الصوت تلقائياً مع الحفاظ على الـ Pitch.

- **FFmpeg Official:** [https://ffmpeg.org/](https://ffmpeg.org/)
- **FFmpeg Builds — Gyan:** [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
- **Direct Download — FFmpeg Essentials:** [https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip)

---

# 🎯 What does Video Speed do?

تستخدم هذه الأداة لتغيير سرعة تشغيل الفيديو مع الحفاظ على التزامن بين:

- 🎥 Video
    
- 🔊 Audio
    
- 🎙️ Voice / Speech
    

السرعات المتوفرة:

|Speed|النتيجة|مدة الفيديو|
|---|---|---|
|`0.5x`|نصف السرعة|×2|
|`0.75x`|أبطأ بـ 25%|×1.33|
|`1.25x`|أسرع بـ 25%|÷1.25|
|`1.5x`|أسرع بـ 50%|÷1.5|
|`2x`|ضعف السرعة|÷2|

مثلاً:

فيديو مدته **10 دقائق**:

- `0.5x` → 20 دقيقة
    
- `0.75x` → 13:20 دقيقة تقريباً
    
- `1.25x` → 8 دقائق
    
- `1.5x` → 6:40 دقائق
    
- `2x` → 5 دقائق
    

---

# ⭐ Best Daily Command

مثلاً لتشغيل الفيديو بسرعة **2x**:

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/2[v];[0:a]atempo=2[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_2x.mp4
```

هذا الأمر يقوم بـ:

1. تسريع الفيديو إلى 2x
    
2. تسريع الصوت إلى 2x
    
3. الحفاظ على Pitch الصوت
    
4. إعادة ترميز الفيديو إلى H.264
    
5. إعادة ترميز الصوت إلى AAC
    
6. جعل MP4 مناسباً للتشغيل والـ streaming
    

---

# 🧠 How Video Speed Works

## `setpts`

الجزء الأساسي لتغيير سرعة الفيديو:

```bash
setpts=PTS/2
```

`PTS` تعني **Presentation Timestamp**، أي التوقيت الذي يحدد متى يتم عرض كل Frame.

### 2x

```bash
setpts=PTS/2
```

يقسم التوقيت على 2 → الفيديو يصبح أسرع بمرتين.

### 1.5x

```bash
setpts=PTS/1.5
```

### 1.25x

```bash
setpts=PTS/1.25
```

### 0.75x

```bash
setpts=PTS/0.75
```

### 0.5x

```bash
setpts=PTS/0.5
```

كلما صغر الـ PTS، يتم عرض الـ Frames بفواصل زمنية أقصر وبالتالي يصبح الفيديو أسرع.

---

# 🔊 Changing Audio Speed

تغيير سرعة الفيديو وحده لا يكفي.

إذا سرّعنا الفيديو ولم نسرّع الصوت، سيصبح هناك اختلاف بينهما.

لذلك نستخدم:

```bash
atempo
```

مثلاً:

```bash
atempo=2
```

يعني تشغيل الصوت بسرعة `2x`.

---

# 🎙️ Pitch Preservation

الميزة المهمة في `atempo` أنه يغيّر **سرعة الصوت بدون تغيير الـ Pitch**.

يعني صوت الشخص لا يصبح حاداً ومزعجاً عند استخدام:

```bash
2x
```

بدلاً من أن يتحول الصوت إلى شيء يشبه الصوت المسرّع، يبقى Pitch الكلام قريباً من الطبيعي.

---

# ⚙️ أهم Parameters

## `-i`

تحديد ملف الإدخال:

```bash
-i input.mp4
```

---

## `-filter_complex`

يستخدم عندما نحتاج إلى معالجة أكثر من Stream أو Filter.

مثلاً:

```bash
-filter_complex "[0:v]setpts=PTS/2[v];[0:a]atempo=2[a]"
```

لدينا هنا مساران:

```text
Video → setpts → [v]

Audio → atempo → [a]
```

---

## `[0:v]`

يعني أول Video Stream في الملف.

```bash
[0:v]
```

---

## `[0:a]`

يعني أول Audio Stream.

```bash
[0:a]
```

إذا لم يكن هناك Audio Stream، فإن هذا الجزء لن يعمل، لذلك يجب التعامل مع الفيديوهات بدون صوت بشكل منفصل.

---

## `setpts=PTS/SPEED`

تغيير سرعة الفيديو.

مثلاً:

```bash
setpts=PTS/1.5
```

يعني سرعة `1.5x`.

---

## `atempo=SPEED`

تغيير سرعة الصوت:

```bash
atempo=1.5
```

---

## `-map`

تحديد Streams التي نريد إخراجها:

```bash
-map "[v]"
-map "[a]"
```

الأول يأخذ الفيديو المعالج.

الثاني يأخذ الصوت المعالج.

---

# 🚀 Ready-to-Use Commands

## 0.5x — Half Speed

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/0.5[v];[0:a]atempo=0.5[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_0.5x.mp4
```

---

## 0.75x

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/0.75[v];[0:a]atempo=0.75[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_0.75x.mp4
```

---

## 1.25x

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/1.25[v];[0:a]atempo=1.25[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_1.25x.mp4
```

---

## 1.5x

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/1.5[v];[0:a]atempo=1.5[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_1.5x.mp4
```

---

## 2x — Double Speed

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/2[v];[0:a]atempo=2[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_2x.mp4
```

---

# ⏱️ Speed vs Duration

قاعدة بسيطة:

```text
New Duration = Original Duration ÷ Speed
```

مثلاً فيديو مدته:

```text
10 minutes
```

### 0.5x

```text
10 ÷ 0.5 = 20 minutes
```

### 1.25x

```text
10 ÷ 1.25 = 8 minutes
```

### 2x

```text
10 ÷ 2 = 5 minutes
```

---

# 🎥 Video Speed ≠ Frame Interpolation

تغيير السرعة لا يعني إنشاء Frames جديدة.

مثلاً عند استخدام:

```bash
2x
```

FFmpeg يعرض الفيديو بسرعة أكبر.

أما **Frame Interpolation** فيقوم بإنشاء Frames جديدة بين الـ Frames الأصلية لجعل الحركة أكثر سلاسة.

مثال:

```text
Normal Speed
↓
Frame 1
Frame 2
Frame 3
Frame 4
```

Frame Interpolation قد ينشئ:

```text
Frame 1
New Frame
Frame 2
New Frame
Frame 3
New Frame
Frame 4
```

لذلك هما أداتان مختلفتان:

|Tool|الوظيفة|
|---|---|
|Video Speed|تغيير سرعة التشغيل|
|Frame Interpolation|إنشاء Frames إضافية للحركة السلسة|
|Video Resolution Converter|تغيير الدقة|
|AI Super Resolution|تحسين/تكبير التفاصيل باستخدام AI|

---

# 🔊 Videos Without Audio

ليس كل فيديو يحتوي على Audio.

مثلاً:

- Screen recordings بدون صوت
    
- Animation
    
- GIF converted to MP4
    
- بعض ملفات الـ stock footage
    
- بعض الـ renders
    

إذا لم يكن هناك Audio، يمكن معالجة الفيديو وحده:

```bash
ffmpeg -i input.mp4 \
-vf "setpts=PTS/2" \
-an \
-c:v libx264 \
-crf 18 \
-preset medium \
output_2x.mp4
```

### `-an`

تعني:

```text
No Audio
```

أي تجاهل Audio Stream تماماً.

---

# 🎚️ CRF

جودة الفيديو الناتج يتم التحكم بها بواسطة:

```bash
-crf 18
```

قيم شائعة:

|CRF|الجودة|الحجم|
|--:|---|---|
|16|عالية جداً|كبير|
|18|ممتازة|كبير|
|20|ممتازة|متوسط|
|23|جيدة|أصغر|
|26|متوسطة|صغير|

قاعدة عامة:

```text
CRF ↓ → Quality ↑ → File Size ↑
CRF ↑ → Quality ↓ → File Size ↓
```

`18` خيار ممتاز عندما تكون الأولوية للجودة.

---

# ⚡ Preset

يحدد سرعة عملية الـ encoding وكفاءتها:

```bash
-preset medium
```

أمثلة:

```text
ultrafast
superfast
veryfast
faster
fast
medium
slow
slower
veryslow
```

بشكل عام:

```text
Preset أسرع
→ Encoding أسرع
→ File أكبر قليلاً

Preset أبطأ
→ Encoding أبطأ
→ Compression أفضل
→ File أصغر عند نفس الجودة تقريباً
```

للاستخدام اليومي:

```bash
-preset medium
```

خيار متوازن.

---

# 🌐 `-movflags +faststart`

```bash
-movflags +faststart
```

ينقل معلومات الـ MP4 المهمة إلى بداية الملف.

هذا مفيد خصوصاً عند تشغيل الفيديو عبر:

- Websites
    
- Browsers
    
- Streaming
    
- Online platforms
    

ويجعل بدء تشغيل الفيديو عبر الإنترنت أسرع في كثير من الحالات.

---

# 🎧 Audio Bitrate

```bash
-b:a 192k
```

يعني Audio bitrate:

```text
192 kbps
```

خيارات شائعة:

```text
128k → جيد
192k → ممتاز للاستخدام العام
256k → جودة أعلى
320k → جودة عالية جداً
```

`192k` خيار متوازن لمعظم الفيديوهات.

---

# 🧩 Important: `atempo`

`atempo` يدعم تغيير السرعة ضمن نطاق محدد لكل Filter.

السرعات المستخدمة في هذه الأداة:

```text
0.5x
0.75x
1.25x
1.5x
2x
```

كلها تقع ضمن النطاق المناسب، لذلك يمكن استخدام `atempo` مباشرة بدون chain إضافي.

للسرعات الأكبر من `2x` أو الأصغر من `0.5x` قد نحتاج إلى دمج أكثر من `atempo` filter.

مثلاً:

```bash
atempo=2,atempo=2
```

تعطي:

```text
4x
```

لأن:

```text
2 × 2 = 4
```

---

# 💡 Practical Examples

## Slow Motion

لجعل فيديو عادي أبطأ:

```text
Original → 0.5x
```

مفيد لـ:

- Sports
    
- Tutorials
    
- Product demonstrations
    
- Motion analysis
    
- Educational content
    

---

## Faster Tutorial

```text
Original → 1.5x
```

مفيد لتقصير:

- Tutorials
    
- Screen recordings
    
- Lectures
    
- Long explanations
    

---

## Very Fast Review

```text
Original → 2x
```

مفيد لمراجعة فيديو طويل بسرعة.

---

# ⚠️ Important Limitations

تغيير السرعة لا يحسن جودة الفيديو.

إذا كان الفيديو منخفض الجودة:

```text
720p → 2x
```

سيصبح أسرع فقط.

لن يؤدي ذلك إلى:

```text
720p → Better Quality
```

ولا يقوم بإضافة تفاصيل جديدة.

لتحسين التفاصيل أو تكبير الدقة نستخدم أدوات أخرى مثل:

**AI Super Resolution / Real-ESRGAN**

---

# 🆚 Which Tool Should I Use?

|إذا كان هدفك|استخدم|
|---|---|
|تغيير سرعة الفيديو|**Video Speed**|
|تغيير Resolution|**Video Resolution Converter**|
|ضغط الفيديو|**Video Compression**|
|تحسين التفاصيل|**AI Super Resolution**|
|جعل الحركة أكثر سلاسة|**Frame Interpolation**|

---

# 📌 Quick Guide

### أريد الفيديو أبطأ:

```text
0.5x
```

### أريد تبطيئه قليلاً:

```text
0.75x
```

### أريد تسريعه قليلاً:

```text
1.25x
```

### أريد تسريع واضح:

```text
1.5x
```

### أريد ضعف السرعة:

```text
2x
```

---

# 🧠 Quick Summary

```text
Video Speed
│
├── 0.5x   → Half Speed
├── 0.75x  → Slower
├── 1.25x  → Slightly Faster
├── 1.5x   → Faster
└── 2x     → Double Speed
```

الفيديو:

```bash
setpts=PTS/SPEED
```

الصوت:

```bash
atempo=SPEED
```

والنتيجة:

```text
Video Speed + Audio Speed
        ↓
   Same Duration Sync
        ↓
   Pitch Preserved
```

> **Video Speed** يغيّر سرعة التشغيل فقط.  
> لا يزيد جودة الفيديو ولا ينشئ Frames جديدة ولا يقوم بعمل AI enhancement.