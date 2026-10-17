> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.

[https://ffmpeg.org/](https://ffmpeg.org/)
[https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
(Download) [https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip)

---

## ⭐ أفضل أمر للاستخدام اليومي

```bash
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output.mp4
```

هذا الأمر يحوّل الفيديو إلى **1080p كحد أقصى** مع الحفاظ على الـ **Aspect Ratio**.

### ماذا يفعل؟

- `-i input.mp4` → الفيديو الأصلي.
    
- `-vf` → تطبيق Video Filter.
    
- `scale=1920:1080` → تحديد أقصى أبعاد للفيديو.
    
- `force_original_aspect_ratio=decrease` → الحفاظ على Aspect Ratio وعدم تشويه الفيديو.
    
- `force_divisible_by=2` → جعل أبعاد الفيديو قابلة للقسمة على 2، وهو مناسب لمعظم Codecs.
    
- `-c:v libx264` → استخدام H.264 لترميز الفيديو.
    
- `-crf 18` → جودة فيديو عالية جدًا.
    
- `-preset medium` → توازن بين سرعة الترميز وكفاءة الضغط.
    
- `-c:a aac` → ترميز الصوت باستخدام AAC.
    
- `-b:a 192k` → Bitrate الصوت 192 kbps.
    
- `-movflags +faststart` → تحسين تشغيل MP4 عبر الإنترنت.
    
- `output.mp4` → الملف الناتج.
    

---

# 📐 Resolution Options

الأداة توفر أربع دقات أساسية:

```text
4K      → 3840 × 2160
1080p   → 1920 × 1080
720p    → 1280 × 720
480p    → 854 × 480
```

---

# 🎬 4K — 3840 × 2160

```bash
ffmpeg -i input.mp4 -vf "scale=3840:2160:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_4K.mp4
```

يستخدم عندما تريد إخراج الفيديو بأبعاد تصل إلى:

```text
3840 × 2160
```

### ⚠️ مهم

إذا كان الفيديو الأصلي أصغر من 4K، فإن رفع Resolution لا يعني استعادة التفاصيل.

مثلاً:

```text
720p
↓
4K
```

سيؤدي إلى **Upscaling** فقط.

لن تصبح التفاصيل مساوية لفيديو 4K أصلي.

---

# 🎬 1080p — 1920 × 1080

```bash
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_1080p.mp4
```

مناسب لـ:

- Full HD
    
- Websites
    
- YouTube
    
- Social Media
    
- الاستخدام اليومي
    

---

# 🎬 720p — 1280 × 720

```bash
ffmpeg -i input.mp4 -vf "scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_720p.mp4
```

مناسب عندما تريد:

- حجم ملف أصغر
    
- سرعة تحميل أفضل
    
- استهلاك بيانات أقل
    
- جودة HD جيدة
    

---

# 🎬 480p — 854 × 480

```bash
ffmpeg -i input.mp4 -vf "scale=854:480:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 128k -movflags +faststart output_480p.mp4
```

مناسب عندما يكون الهدف الأساسي:

- تقليل حجم الفيديو
    
- تقليل استهلاك الإنترنت
    
- الحصول على نسخة منخفضة الدقة
    

---

# 📐 الحفاظ على Aspect Ratio

الجزء المهم من الأمر هو:

```bash
force_original_aspect_ratio=decrease
```

### ماذا يفعل؟

يمنع الفيديو من أن يتمدد أو ينضغط بشكل غير طبيعي.

مثلاً فيديو:

```text
1920 × 1080
16:9
```

عند تحويله إلى 720p:

```text
1280 × 720
```

يبقى:

```text
16:9
```

---

## 🎞️ مثال على فيديو بنسبة مختلفة

إذا كان الفيديو:

```text
1920 × 800
```

ونريد تحويله إلى 1080p:

```bash
-vf "scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2"
```

لن يتم إجباره على:

```text
1920 × 1080
```

بل سيحافظ على شكله الأصلي تقريبًا:

```text
1920 × 800
```

لأن الـ Aspect Ratio أهم من إجبار الفيديو على أبعاد ثابتة.

---

# 🧠 `scale`

الصيغة الأساسية:

```bash
scale=WIDTH:HEIGHT
```

مثال:

```bash
scale=1920:1080
```

يعني:

```text
Maximum Width  → 1920
Maximum Height → 1080
```

لكن `scale` وحده يمكن أن يشوه الفيديو إذا كانت أبعاده مختلفة.

لذلك نستخدم معه:

```bash
force_original_aspect_ratio=decrease
```

---

# ⭐ `force_original_aspect_ratio`

```bash
force_original_aspect_ratio=decrease
```

يحافظ على نسبة أبعاد الفيديو الأصلية.

يوجد خياران مهمان:

```text
decrease
increase
```

### `decrease`

يضمن أن الفيديو لا يتجاوز الأبعاد المطلوبة.

مثالي لتحويل الفيديو إلى:

```text
4K
1080p
720p
480p
```

### `increase`

يضمن الوصول إلى الأبعاد المطلوبة أو تجاوزها مع الحفاظ على النسبة.

يُستخدم في حالات مختلفة مثل تجهيز الفيديو لإضافة Padding أو Cropping.

لأداة Resolution Converter الحالية:

```text
decrease ⭐
```

هو الخيار المناسب.

---

# 🔢 `force_divisible_by=2`

```bash
force_divisible_by=2
```

يجعل أبعاد الفيديو قابلة للقسمة على 2.

مثلاً بدل:

```text
1279 × 719
```

يمكن أن تصبح:

```text
1278 × 718
```

وهذا مفيد للتوافق مع بعض أنظمة الترميز مثل H.264.

---

# 🚀 Upscaling vs Downscaling

## 📈 Upscaling

رفع الدقة:

```text
720p
↓
1080p
```

أو:

```text
1080p
↓
4K
```

يضيف Pixels لكنه **لا يعيد التفاصيل المفقودة فعليًا**.

---

## 📉 Downscaling

خفض الدقة:

```text
4K
↓
1080p
```

أو:

```text
1080p
↓
720p
```

يقلل عدد الـ Pixels وبالتالي يمكن أن يقل حجم الملف.

---

# ⚠️ Video Resolution ≠ Video Quality

من المهم جدًا التفريق بين:

```text
Resolution
```

و:

```text
Quality
```

مثال:

```text
720p Low Quality
↓
4K
```

قد يصبح الفيديو:

```text
3840 × 2160
```

لكن هذا لا يجعله بجودة فيديو 4K أصلي.

الـ Resolution أصبحت 4K، لكن التفاصيل الأصلية لم تتغير بشكل سحري.

---

# 🤖 AI Upscaling

إذا كان الهدف:

> تحويل فيديو منخفض الدقة إلى فيديو أعلى دقة مع محاولة تحسين التفاصيل

فالأداة العادية ليست الخيار الأفضل.

تحتاج إلى:

```text
AI Video Upscaling
```

مثل أدوات تعتمد على Video Super Resolution / AI models.

### القاعدة:

```text
تغيير الدقة فقط
→ Video Resolution Converter ⭐

رفع الدقة + محاولة إعادة بناء التفاصيل
→ AI Video Upscaling
```

---

# 🎯 4K / 1080p / 720p / 480p — Quick Guide

```text
4K
→ أعلى Resolution
→ مناسب للفيديوهات عالية الجودة
→ ملفات أكبر

1080p
→ أفضل توازن للاستخدام العام ⭐
→ Full HD

720p
→ حجم أصغر
→ جودة HD جيدة

480p
→ حجم صغير جدًا
→ جودة أقل
```

---

# 🎬 أمثلة عملية

## تحويل 4K إلى 1080p

```bash
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_1080p.mp4
```

---

## تحويل 1080p إلى 720p

```bash
ffmpeg -i input.mp4 -vf "scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output_720p.mp4
```

---

## تحويل 1080p إلى 480p

```bash
ffmpeg -i input.mp4 -vf "scale=854:480:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 128k -movflags +faststart output_480p.mp4
```

---

# ⚡ الحفاظ على الجودة أثناء تغيير الدقة

لجودة عالية:

```bash
-crf 18
```

لجودة جيدة وحجم أصغر:

```bash
-crf 23
```

لضغط أكبر:

```bash
-crf 26
```

### القاعدة:

```text
CRF أقل
→ جودة أعلى
→ حجم أكبر

CRF أعلى
→ جودة أقل
→ حجم أصغر
```

---

# ⚙️ Preset

يمكن استخدام:

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

كلما اتجهنا نحو:

```text
slower
```

يزداد وقت الترميز، لكن يمكن الحصول على كفاءة ضغط أفضل عند نفس مستوى الجودة.

### للاستخدام اليومي:

```bash
-preset medium
```

### إذا كانت السرعة أقل أهمية:

```bash
-preset slow
```

---

# 🚀 NVIDIA NVENC

إذا كان لديك NVIDIA GPU، يمكن استخدام NVENC لتسريع عملية الترميز.

## H.264 NVENC

```bash
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2" -c:v h264_nvenc -cq 20 -preset p5 -c:a aac -b:a 192k -movflags +faststart output_1080p.mp4
```

### أهم الخيارات

- `h264_nvenc` → استخدام NVIDIA GPU لترميز H.264.
    
- `-cq 20` → التحكم بجودة الفيديو.
    
- `-preset p5` → توازن جيد بين السرعة والكفاءة.
    
- `-c:a aac` → ترميز الصوت.
    
- `-b:a 192k` → Bitrate الصوت.
    

---

# 🧠 CPU vs NVIDIA NVENC

### CPU — libx264

```bash
-c:v libx264
```

**مناسب عندما تريد:**

- كفاءة ضغط ممتازة
    
- توافقًا واسعًا
    
- تحكمًا جيدًا بالجودة
    

### NVIDIA NVENC

```bash
-c:v h264_nvenc
```

**مناسب عندما تريد:**

- سرعة ترميز عالية جدًا
    
- الاستفادة من NVIDIA GPU
    
- معالجة عدد كبير من الفيديوهات بسرعة
    

### القاعدة:

```text
أفضل كفاءة ضغط
→ libx264

أسرع ترميز
→ NVENC ⭐
```

---

# 📌 Important

هذه الأداة مخصصة لـ **تغيير Resolution** وليست أداة لتحسين الفيديو بالـ AI.

```text
Video Resolution Converter
→ FFmpeg
→ Resolution
→ Scaling
→ Aspect Ratio
```

بينما:

```text
AI Video Upscaling
→ AI Model
→ Detail Reconstruction
→ Quality Enhancement
```

إذا كان الفيديو الأصلي منخفض الدقة، لا تتوقع أن مجرد تحويله إلى 4K سيجعله واضحًا مثل فيديو 4K أصلي.