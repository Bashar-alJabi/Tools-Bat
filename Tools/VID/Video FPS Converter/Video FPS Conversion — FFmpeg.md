> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `System/Bin` لها الأولوية. راجع `README.md` و`System/Docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
[https://ffmpeg.org/](https://ffmpeg.org/)
[https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
(Download) [https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip)

---

**FPS = Frames Per Second**

وهو عدد الإطارات التي يتم عرضها في الثانية الواحدة.

أمثلة:

```text
24 FPS → 24 إطار في الثانية
30 FPS → 30 إطار في الثانية
60 FPS → 60 إطار في الثانية
```

تغيير الـFPS لا يعني تغيير سرعة الفيديو.

مثلاً:

```text
30 FPS → 60 FPS
```

الفيديو يبقى بنفس المدة والسرعة، لكن يصبح معدل الإطارات المستهدف 60 FPS.

---

# ⭐ أفضل أمر للاستخدام اليومي

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k -movflags +faststart output.mp4
```

### ماذا يفعل؟

- `-i input.mp4` → الفيديو الأصلي.
    
- `-vf "fps=30"` → تحويل الفيديو إلى 30 FPS.
    
- `-c:v libx264` → ترميز الفيديو باستخدام H.264.
    
- `-crf 18` → جودة فيديو عالية.
    
- `-preset medium` → توازن بين سرعة الترميز وكفاءة الضغط.
    
- `-c:a aac` → ترميز الصوت باستخدام AAC.
    
- `-b:a 192k` → Audio Bitrate بقيمة 192 kbps.
    
- `-movflags +faststart` → تحسين تشغيل MP4 عبر الإنترنت.
    
- `output.mp4` → الملف الناتج.
    

---

# 🎯 اختيار FPS

القيم الشائعة:

```text
24 FPS
25 FPS
30 FPS
50 FPS
60 FPS
```

## 24 FPS

```text
24 FPS
```

مناسب غالبًا لـ:

- الأفلام.
    
- المحتوى السينمائي.
    
- الفيديوهات ذات الطابع السينمائي.
    

---

## 25 FPS

```text
25 FPS
```

مرتبط تاريخيًا بمعيار PAL ويستخدم في بعض أنظمة الفيديو والبث.

---

## 30 FPS

```text
30 FPS
```

مناسب جدًا للاستخدام العام:

- YouTube
    
- Social Media
    
- تسجيل الشاشة
    
- الفيديوهات اليومية
    

---

## 50 FPS

```text
50 FPS
```

مناسب عندما تكون الحركة أكثر سلاسة مطلوبة، خصوصًا في بعض أنظمة البث والمحتوى الأوروبي.

---

## 60 FPS ⭐

```text
60 FPS
```

مناسب للمحتوى الذي يحتوي على حركة سريعة:

- Gaming
    
- Sports
    
- Screen Recording
    
- محتوى يحتاج Motion أكثر سلاسة
    

---

# ⚙️ `fps` Filter

الأمر الأساسي لتغيير الـFPS هو:

```bash
-vf "fps=30"
```

أو:

```bash
-vf "fps=60"
```

أو:

```bash
-vf "fps=24"
```

### مثال

```bash
ffmpeg -i input.mp4 -vf "fps=60" output.mp4
```

---

# 🔄 FPS Conversion

## من FPS أعلى إلى FPS أقل

مثلاً:

```text
60 FPS → 30 FPS
```

سيتم التخلص من بعض الإطارات للوصول إلى 30 FPS.

```bash
ffmpeg -i input.mp4 -vf "fps=30" output.mp4
```

---

## من FPS أقل إلى FPS أعلى

مثلاً:

```text
30 FPS → 60 FPS
```

سيقوم FFmpeg بإنشاء الإطارات المطلوبة باستخدام آلية الـ`fps` filter للوصول إلى المعدل المستهدف.

```bash
ffmpeg -i input.mp4 -vf "fps=60" output.mp4
```

> **مهم:** رفع FPS باستخدام `fps` filter ليس AI Frame Interpolation، ولا يعني أنه سيولد حركة جديدة بجودة تقنية متقدمة.

---

# ⚠️ FPS Conversion ≠ Frame Interpolation

هناك فرق مهم بين:

```text
FPS Conversion
```

و:

```text
Frame Interpolation
```

### FPS Conversion

يستخدم:

```bash
-vf "fps=60"
```

وهو مناسب لتحويل معدل الإطارات إلى قيمة محددة.

### Frame Interpolation

يستخدم تقنيات متقدمة لإنشاء إطارات وسيطة اعتمادًا على الحركة بين الإطارات الأصلية.

يُستخدم عندما يكون الهدف:

```text
30 FPS → 60 FPS
```

مع محاولة جعل الحركة أكثر سلاسة، وليس فقط الوصول إلى رقم FPS أعلى.

---

# 🎥 الحفاظ على سرعة الفيديو

تغيير FPS باستخدام:

```bash
-vf "fps=30"
```

لا يغير سرعة تشغيل الفيديو.

مثلاً:

```text
Original:
30 FPS
10 seconds

Output:
60 FPS
10 seconds
```

المدة تبقى تقريبًا نفسها.

---

# 🔊 Audio

تغيير FPS لا يتطلب تغيير سرعة الصوت.

لذلك يمكن الاحتفاظ بالـAudio مع الفيديو:

```bash
-map 0:a?
```

علامة `?` تعني أن Audio Stream اختياري.

إذا كان الفيديو يحتوي على Audio:

```text
Video + Audio → Video + Audio
```

وإذا لم يكن يحتوي على Audio:

```text
Video only → Video only
```

---

# 🎵 Audio Encoding

عند إخراج MP4 يمكن استخدام:

```bash
-c:a aac -b:a 192k
```

### AAC

Codec صوت شائع ومتوافق بشكل ممتاز مع MP4.

### 192k

Audio Bitrate:

```text
192 kbps
```

وهو مستوى جيد جدًا للاستخدام العام.

---

# 📐 Resolution

تحويل FPS لا يغيّر Resolution بحد ذاته.

مثلاً:

```text
1920×1080 @ 30 FPS
```

يمكن أن يصبح:

```text
1920×1080 @ 60 FPS
```

تبقى الدقة:

```text
1920×1080
```

---

# 🎬 H.264 / x264

لترميز الفيديو باستخدام H.264:

```bash
-c:v libx264
```

مثال:

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v libx264 -crf 18 -preset medium output.mp4
```

### لماذا H.264؟

- توافق ممتاز.
    
- مناسب للمواقع.
    
- مناسب لـYouTube وSocial Media.
    
- مدعوم على معظم الأجهزة.
    
- خيار آمن للاستخدام العام.
    

---

# 🎯 CRF

عند استخدام:

```bash
-c:v libx264
```

يمكن التحكم بالجودة عبر:

```bash
-crf
```

كلما **قل الرقم**:

→ جودة أعلى  
→ حجم أكبر

|CRF|الجودة|الحجم|
|--:|---|---|
|18|عالية جدًا|كبير|
|20|ممتازة|كبير نسبيًا|
|**23**|**توازن ممتاز ⭐**|متوسط|
|25|جيدة جدًا|أصغر|
|28|ضغط قوي|صغير|

### ⭐ القاعدة السريعة

```text
CRF 18 → جودة عالية جدًا
CRF 20 → جودة ممتازة
CRF 23 → أفضل توازن للاستخدام العام
CRF 25 → حجم أصغر
CRF 28 → ضغط قوي
```

---

# ⚙️ Preset

خيارات x264:

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

يزداد وقت الترميز، ويمكن الحصول على كفاءة ضغط أفضل عند نفس مستوى الجودة.

### ⭐ الاستخدام اليومي

```bash
-preset medium
```

### ضغط أكثر كفاءة مع وقت أطول

```bash
-preset slow
```

---

# ⚡ NVIDIA NVENC

إذا كان لديك NVIDIA GPU يمكن استخدام Hardware Encoding عبر NVENC.

## H.264 NVENC

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v h264_nvenc -cq 23 -preset p5 -c:a aac -b:a 192k -movflags +faststart output.mp4
```

### أهم الخيارات

- `h264_nvenc` → H.264 باستخدام NVIDIA GPU.
    
- `cq 23` → التحكم بجودة الفيديو.
    
- `preset p5` → توازن جيد بين السرعة والكفاءة.
    
- `aac` → ترميز الصوت.
    
- `192k` → Audio Bitrate.
    

---

# 🎯 NVENC CQ

NVENC يستخدم:

```bash
-cq
```

بدلاً من CRF الخاص بـx264.

كلما قل الرقم:

→ جودة أعلى  
→ حجم أكبر

مثال:

```text
CQ 18 → جودة عالية جدًا
CQ 20 → جودة ممتازة
CQ 23 → توازن جيد ⭐
CQ 25 → ضغط أكبر
CQ 28 → حجم أصغر
```

> **ملاحظة:** `CQ 23` ليس مساويًا بشكل مباشر لـ`CRF 23`. القيمتان تستخدمان أنظمة مختلفة ولا يمكن اعتبارهما متطابقتين في الجودة أو الحجم.

---

# ⚙️ NVENC Preset

NVENC يستخدم:

```text
p1
p2
p3
p4
p5
p6
p7
```

كلما اتجهنا نحو:

```text
p7
```

يزداد وقت الترميز ويمكن تحسين كفاءة الضغط.

### ⭐ الاستخدام اليومي

```bash
-preset p5
```

---

# 🚀 H.265 / HEVC

يمكن استخدام H.265 لتقليل حجم الملف مقارنةً بـH.264 في كثير من الحالات.

## CPU

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v libx265 -crf 26 -preset medium -c:a aac -b:a 192k output.mp4
```

## NVIDIA

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v hevc_nvenc -cq 26 -preset p5 -c:a aac -b:a 192k output.mp4
```

### H.265 مقارنة بـ H.264

**H.265 / HEVC:**

- كفاءة ضغط أفضل عادةً.
    
- حجم أصغر عادةً عند جودة مشابهة.
    
- ترميز أبطأ مع CPU.
    
- توافق أقل في بعض الأجهزة والأنظمة.
    

**H.264:**

- توافق أعلى.
    
- مناسب جدًا للمواقع والمشاركة.
    
- خيار آمن لمعظم الاستخدامات.
    

### ⭐ القاعدة

```text
أقصى توافق → H.264
حجم أصغر → H.265 / HEVC
```

---

# 🌐 `-movflags +faststart`

```bash
-movflags +faststart
```

يُستخدم مع ملفات MP4 لتحسين تشغيل الفيديو عبر الإنترنت.

### ماذا يفعل؟

ينقل معلومات الـ**MOOV Atom** من نهاية ملف MP4 إلى بدايته.

وبالتالي:

- يبدأ الفيديو بالتشغيل بشكل أسرع أثناء التحميل.
    
- مناسب للفيديوهات التي ستُرفع على Website.
    
- مفيد للتشغيل التدريجي عبر الإنترنت.
    
- لا يضغط الفيديو.
    
- لا يغيّر جودة الصورة.
    
- قد يضيف وقتًا بسيطًا بعد انتهاء الترميز لإعادة ترتيب الملف.
    

### ⭐ القاعدة السريعة

```text
فيديو للاستخدام المحلي فقط
→ اختياري

فيديو للموقع / الإنترنت
→ يُنصح باستخدامه ⭐
```

---

# 🧩 أمثلة جاهزة

## 24 FPS

```bash
ffmpeg -i input.mp4 -vf "fps=24" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k output.mp4
```

## 25 FPS

```bash
ffmpeg -i input.mp4 -vf "fps=25" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k output.mp4
```

## 30 FPS ⭐

```bash
ffmpeg -i input.mp4 -vf "fps=30" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k output.mp4
```

## 50 FPS

```bash
ffmpeg -i input.mp4 -vf "fps=50" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k output.mp4
```

## 60 FPS

```bash
ffmpeg -i input.mp4 -vf "fps=60" -c:v libx264 -crf 18 -preset medium -c:a aac -b:a 192k output.mp4
```

---

# ⭐ Quick Reference

```text
FPS
→ عدد الإطارات في الثانية

24 FPS
→ سينمائي

25 FPS
→ PAL

30 FPS
→ استخدام عام ⭐

50 FPS
→ حركة سلسة

60 FPS
→ حركة عالية السلاسة / Gaming / Sports

-vf "fps=30"
→ تحويل الفيديو إلى 30 FPS

libx264
→ H.264 عبر CPU

h264_nvenc
→ H.264 عبر NVIDIA GPU

libx265
→ H.265 عبر CPU

hevc_nvenc
→ H.265 عبر NVIDIA GPU

CRF
→ جودة x264/x265

CQ
→ جودة NVENC

-preset medium
→ توازن جيد للـCPU

-preset p5
→ توازن جيد لـNVENC

-c:a aac
→ Audio Codec

-b:a 192k
→ Audio Bitrate

-movflags +faststart
→ تحسين تشغيل MP4 عبر الإنترنت
```