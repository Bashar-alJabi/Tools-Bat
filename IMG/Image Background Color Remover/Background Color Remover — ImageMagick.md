> **تحديث التشغيل:** ابدأ بـ `START_HERE.bat` في جذر المشروع. لا يلزم تعديل PATH أو التثبيت العام؛ النسخ المحلية داخل `_bin` لها الأولوية. راجع `README.md` و`docs/DEPENDENCIES.md` في الجذر للإعداد الحالي. الأوامر أدناه مرجع يدوي، وروابط التنزيل القديمة ليست ما يستخدمه نظام التجهيز. ملفات Input الأصلية تُحفظ، والنتائج الموجودة تُتخطّى، وأخطاء المعالجة ترجع كودًا غير صفري. صيغ GIF/TIFF/WebP متعددة الإطارات تُحفظ عندما يدعم الناتج ذلك، وتُرفض العمليات غير المدعومة برسالة واضحة.
ImageMagick أداة قوية لتحويل الصور بين مختلف الصيغ من CMD / Cmder.

[https://imagemagick.org/](https://imagemagick.org/)

(Download): [https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe](https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-30/ImageMagick-7.1.2-30-Q16-HDRI-x64-dll.exe)

---
## 📌 Overview

أداة لإزالة **خلفية بلون موحّد** من الصور باستخدام **ImageMagick** وتحويلها إلى خلفية شفافة `PNG`.

> ⚠️ هذه الأداة **ليست AI** ولا تفهم محتوى الصورة أو تميّز الشخص عن الخلفية.  
> هي تعتمد على **لون الخلفية + Fuzz/Tolerance**.

مناسبة خصوصًا للصور التي تحتوي على:

- خلفية بيضاء
    
- خلفية سوداء
    
- خلفية بلون موحّد
    

---

## ⚙️ How It Works

الأداة تطلب من المستخدم اختيار:

### 1. Background Color

يمكن اختيار:

- **White**
    
- **Black**
    
- **Custom Color**
    

مثال Custom:

```text
#00FF00
```

---

### 2. Fuzz / Tolerance

تحدد مدى اختلاف الألوان الذي سيتم اعتباره جزءًا من اللون المحدد.

|Fuzz|النتيجة|
|--:|---|
|`0%`|اللون المطابق تقريبًا فقط|
|`5%`|اختلافات بسيطة جدًا|
|`10%`|اختلافات أكبر|
|`20%`|نطاق واسع من درجات اللون|

مثال:

إذا كانت الخلفية بيضاء وفيها ظلال رمادية خفيفة:

```text
5%
```

قد يترك بعض الظلال.

بينما:

```text
10% - 20%
```

يمكن أن يزيل جزءًا أكبر من الخلفية.

> ⚠️ رفع الـ Fuzz كثيرًا قد يؤدي إلى إزالة أجزاء من العنصر نفسه إذا كانت قريبة من لون الخلفية.

---

## 🧠 Important Limitation

ImageMagick لا يقوم بعملية **Background Detection** حقيقية.

مثلاً إذا اخترنا:

```text
White
```

فالأداة ستجعل الألوان القريبة من الأبيض شفافة أينما ظهرت في الصورة.

يعني إذا كان العنصر نفسه يحتوي على مناطق بيضاء، قد تصبح هذه المناطق شفافة أيضًا.

وهذا يختلف عن أدوات AI مثل:

**Background Remover — AI**

التي تحاول فهم:

```text
Foreground
        ↓
Subject / Object

Background
        ↓
Everything behind it
```

---

## 🔧 Core ImageMagick Command

العملية الأساسية:

```bat
magick "input.jpg" ^
    -alpha on ^
    -fuzz 10% ^
    -transparent "white" ^
    "output.png"
```

### Parameters

#### `-alpha on`

تفعيل قناة Alpha حتى يمكن إنشاء الشفافية.

#### `-fuzz 10%`

تحديد مدى تشابه الألوان مع اللون المستهدف.

#### `-transparent "white"`

جعل اللون الأبيض والألوان القريبة منه شفافة.

#### `output.png`

الحفظ بصيغة PNG للحفاظ على الشفافية.

---

## 📥 Input

يدعم مجموعة من صيغ الصور الشائعة:

```text
JPG
JPEG
PNG
WEBP
BMP
TIF
TIFF
GIF
AVIF
```

---

## 📤 Output

جميع النتائج يتم حفظها كـ:

```text
PNG
```

لأن PNG يدعم الشفافية بشكل مناسب.

---

## 📊 Processing Features

الأداة تدعم:

- Batch processing
    
- Fixed `Input` folder
    
- Fixed `Output` folder
    
- Skip existing outputs
    
- Success counter
    
- Failed counter
    
- Skipped counter
    
- Cleanup failed output
    
- Dependency validation
    
- Input validation
    

---

## 🆚 AI vs Non-AI

### Background Remover — AI

يستخدم:

```text
BRIA RMBG
rembg
ONNX
```

ويحاول اكتشاف العنصر والخلفية تلقائيًا.

**أفضل عندما:**

- الخلفية معقدة
    
- الشخص أمام خلفية غير موحدة
    
- يوجد أكثر من لون في الخلفية
    

---

### Background Color Remover — ImageMagick

يستخدم:

```text
ImageMagick
Color Matching
Fuzz / Tolerance
```

**أفضل عندما:**

- الخلفية لون واحد
    
- صور المنتجات
    
- خلفية بيضاء أو سوداء
    
- Logos / graphics
    
- صور بسيطة
    

---

## 💡 Example

صورة منتج بخلفية بيضاء:

```text
Input
  ↓
Background Color: White
  ↓
Fuzz: 10%
  ↓
ImageMagick
  ↓
Transparent PNG
```

النتيجة:

```text
Product
   +
Transparent Background
```

---

## ⚠️ Best Practices

ابدأ عادةً بـ:

```text
5%
```

إذا بقيت أجزاء من الخلفية:

```text
10%
```

وإذا كانت الخلفية تحتوي على اختلافات كبيرة:

```text
20%
```

لا تستخدم Fuzz عاليًا بشكل عشوائي، لأنه قد يبدأ بإزالة أجزاء من العنصر نفسه.

---

## 📝 Summary

**Background Color Remover — ImageMagick** هو أداة Non-AI لإزالة الخلفيات ذات الألوان الموحدة.

تعتمد على:

```text
Target Color
      +
Fuzz / Tolerance
      ↓
Transparent PNG
```

وهي مكملة لأداة **AI Background Remover** وليست بديلًا عنها.