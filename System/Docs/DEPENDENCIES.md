# سجل الاعتمادات — 2026-10-18

لا توجد برامج خارجية مضمنة حاليًا في توزيع المصدر. تم اكتشاف البرامج المثبتة على جهاز الاختبار دون تعديلها أو تنزيل بدائل لها. سجل الأدوات القابل للقراءة آليًا هو `System/Shared/tools.json`، وحزم التنزيل هي `System/Shared/packages.json`.

| الاعتماد الحقيقي | الأدوات التي تحتاجه | الحالة | النسخة المحلية عند البدء | النسخة الموجودة على جهاز الاختبار |
|---|---|---|---|---|
| FFmpeg | أدوات VID الأصلية الإحدى عشرة وVideo Thumbnail؛ Audio Converter؛ الأدوات الجديدة Video Trim/Rotate/To GIF/Remux/Frames وAudio Trim/Normalize/Fade/Channels/Concatenate | إلزامي لهذه الأدوات فقط | لا توجد | 9.0.1 Essentials، مثبت ضمن PATH على هذا الجهاز |
| FFprobe | Media Info وVideo Trim وAudio Trim وAudio Fade | إلزامي لهذه الأدوات، ويأتي مع حزمة FFmpeg | لا توجد | 9.0.1 مع FFmpeg |
| ImageMagick `magick.exe` | أدوات IMG الأصلية التسع وImage Rotate/Flip/Grayscale/Border/Info | إلزامي لها فقط | لا توجد | 7.1.2-30 Q16 HDRI |
| Ghostscript `gswin64c.exe` أو `gswin32c.exe` | Compress PDF وMerge PDF وPDF Split/To Images/Text | إلزامي لها فقط | لا توجد | 10.07.1 |
| Windows PowerShell 5.1 و.NET Framework | جميع المشغلات والعمليات المشتركة | متطلب Windows أساسي | مكوّن نظام | PowerShell 5.1 |
| Windows `tar.exe` | استخراج حزمة ImageMagick 7z أثناء التجهيز فقط | اختياري؛ يمكن الاستخراج اليدوي | مكوّن نظام، لا يُوزع من المشروع | bsdtar 3.8.8 |
| NVIDIA GPU وتعريف متوافق | تسريع ضغط الفيديو عبر NVENC | اختياري؛ CPU بديل تلقائي | ليس جزءًا من المشروع | لا يُفترض توفره |
| Arial | نص العلامة المائية وأسماء Contact Sheet | خط Windows المعتاد؛ قد يحتاج مستخدم نسخة Windows مختزلة توفير خط | مكوّن نظام | نجح إنشاء النص في الاختبارات |

مراجع BRIA/rembg/ONNX/Real-ESRGAN وFrame Interpolation في الشروح القديمة أمثلة مقارنة وليست اعتمادات تنفيذية أو أدوات موجودة. Git وPython وNode و7-Zip ليست متطلبات تشغيل للمشروع.

أدوات Rename Copies وSort Copies وText Encoding وFolder Compare وJSON Format وNetwork Info وPing Host لا تضيف اعتمادًا خارجيًا. أدوات الشبكة تستخدم .NET المدمج، وPing قد يُمنع داخل بيئة عزل أو بواسطة الجدار الناري دون أن تحتاج الأداة صلاحية Administrator في Windows العادي.

## اكتشاف النسخ والتحقق

يبحث البرنامج أولًا بشكل نسبي داخل `System/Bin`، ثم PATH وProgram Files، دون حفظ مسار الجهاز في الإعدادات. لا يُستخدم `convert.exe` الخاص بنظام Windows بدل ImageMagick. يجرب تشغيل الملف، ويتحقق من الإصدار، ثم يفحص:

- FFmpeg 6 أو أحدث: encoders الأساسية `libx264` و`libmp3lame` و`aac`. تتطلب خيارات HEVC/Opus وجود `libx265`/`libopus` في البناء المستخدم؛ غيابها يظهر عند اختيار الوظيفة. البناء المقترح يتضمنها.
- ImageMagick 7: قراءة وكتابة PNG وJPEG. الصيغ الإضافية مثل AVIF تعتمد على delegates الموجودة في البناء، ويظهر فشل واضح إذا لم تتوفر.
- Ghostscript 10.05 أو أحدث: وجود جهاز `pdfwrite`. يفضّل استخدام الإصدار الرسمي المحدث المناسب للنظام.
- FFprobe 6 أو أحدث: بصمة الإصدار الصحيحة.

هذه فحوص توافق وظيفية وليست شهادة أمان لأي ملف EXE يضعه المستخدم في PATH أو `System/Bin`؛ يجب أن تكون النسخة اليدوية من مصدر موثوق.

## المصادر والحزم المحددة

1. **FFmpeg وFFprobe:** [الموقع الرسمي والتنزيلات](https://ffmpeg.org/download.html) يوجّه إلى موزعي Windows. اختير [Gyan Builds](https://www.gyan.dev/ffmpeg/builds/) لبناء Essentials الثابت **9.0.2** بصيغة ZIP، قرابة 109 MB. الرابط يتضمن الإصدار؛ لا يُستخدم `latest`. بصمة SHA-256 ثابتة في manifest وتحققت من مطابقتها لبيانات [إصدار الناشر](https://github.com/GyanD/codexffmpeg/releases/tag/9.0.2) وملف البصمة المنشور عبر التصفح. لم يُنزّل أرشيف البرنامج أثناء التطوير، التزامًا بتعليمات عدم تنزيل برامج جديدة دون موافقة.
2. **ImageMagick:** [صفحة التنزيل الرسمية](https://imagemagick.org/download/) و[الإصدار المثبت 7.1.2-34](https://github.com/ImageMagick/ImageMagick/releases/tag/7.1.2-34). اختير portable Q16 HDRI x64 بصيغة 7z، قرابة 12 MB. البصمة ثابتة في manifest ومنشورة ضمن أصول الإصدار الرسمي.
3. **Ghostscript:** [التنزيل الرسمي](https://ghostscript.com/releases/gsdnld.html) و[إصدار Artifex 10.08.0](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080). حزمة Windows x64 قرابة 63 MB، وبصمتها ثابتة من أصول الإصدار الرسمي. تُحفظ داخل `System/Downloads` **دون تشغيل المثبت**. لا توجد في هذا الإعداد حزمة Ghostscript Portable رسمية جاهزة تم التحقق منها؛ لا تُقدّم نسخة طرف ثالث على أنها رسمية.

أحجام الحزم تقريبية. تُحفظ توزيعات FFmpeg/ImageMagick كاملة داخل `System/Bin` بعد الاستخراج في مساحة مؤقتة وفحص EXE والإصدار. إذا وُجد مجلد قديم مكسور يُحفظ دون حذف، مع طلب التدخل اليدوي. إذا أصبحت الروابط المثبتة غير متاحة لا ينتقل النظام تلقائيًا إلى إصدار غير متحقق منه.

بصمات SHA-256 المعتمدة:

```text
FFmpeg 9.0.2 ZIP
60f467265b1e312373dbcd92200c2618a74850f98d3d078e94296bb3fa2047ba
ImageMagick 7.1.2-34 portable Q16 HDRI x64 7z
8dcfd3644b7fc20a92aeedeb4798024e5947f25f4d7c0c313c883fbca3d723e6
Ghostscript 10.08.0 Windows x64 installer
52a91b8bf09298788d7a57b9206127026c23eacd75405f0a131e26dc381dce50
```

## الترخيص وإعادة التوزيع

- بناء Gyan المختار موصوف بأنه **GPLv3**. تختلف رخصة FFmpeg باختلاف خيارات البناء والمكتبات؛ راجع [FFmpeg Legal](https://ffmpeg.org/legal.html) وملفات COPYING وREADME للبناء نفسه. عند تسليم ملفات ثنائية يجب توفير إشعارات الترخيص والمصدر المطابق وآلية توزيعه وفق الرخصة، بما يشمل المكتبات المضمنة. نسخ الأرشيف الثنائي وحده ليس بديلًا عن الوفاء بهذه المتطلبات.
- ImageMagick تحت [ImageMagick License](https://imagemagick.org/license/). احتفظ بالرخصة وإشعارات الحقوق ومتطلبات مكتبات delegates المرفقة. التوزيعة الكاملة تُحفظ حتى لا تُفقد هذه الملفات.
- Ghostscript مرخص تحت **AGPLv3 أو ترخيص تجاري من Artifex** وفق [صفحة المنتج الرسمية](https://ghostscript.com/releases/gsdnld.html). يلزم اختيار شروط مناسبة لطريقة التوزيع والالتزام بالمصدر والإشعارات عند إعادة توزيعه. المشروع لا يمنح ترخيصًا تجاريًا ولا يفترض أن تضمينه في أي منتج مغلق مسموح تلقائيًا.
- مكونات Windows والخطوط وtar لا تُنسخ من جهاز التطوير ولا تُعاد تعبئتها مع المشروع. تعتمد الأدوات على مكونات Windows المتوفرة عند المستخدم.

لا توجد عملية تعديل PATH أو Registry أو سياسة PowerShell الدائمة، ولا يُشغَّل كود بعيد. الموافقة تكون لكل حزمة عند الاستخدام الفعلي، ولا تُشغّل EXE المثبتات تلقائيًا. لم تُنفّذ تنزيلات برامج أثناء التطوير.

## توسعة 2026-10-20

أصبح الفهرس85 أداة. لم تُضف برامج أو حزم جديدة؛ يقرأ START_HERE أسماء الأدوات واعتماداتها من System/Shared/tools.json. أدوات PDF الأربع الجديدة تستخدم Ghostscript الحالي، والتحويل CSV يستخدم Microsoft.VisualBasic المدمج مع .NET Framework دون تنزيل. حرق الترجمة يتطلب subtitles/libass داخل بناء FFmpeg وخطًا يدعم العربية؛ فحص المرشح جزء من START_HERE و--check الخاص بالأداة. أدوات التحليل تجمع إحصاءات ولا تشتري خدمات أو تتصل بالإنترنت.

## إضافة qpdf في2026-10-21

أدوات PDF Protect وPDF Unlock وPDF Watermark تحتاج qpdf12+، للأولى تشفير AES-256 حديث وتمرير السر عبر stdin الخاص بخيار @- دون argv أو ملف أسرار. الحزمة المثبتة الإصدار والبصمة في packages.json من [إصدارات qpdf الرسمية](https://github.com/qpdf/qpdf/releases/tag/v12.4.2)، Apache-2.0 مع إبقاء إشعارات المكتبات المرفقة. START_HERE يجهّز ZIP محليًا بعد الموافقة، ولا يحتاج تثبيتًا عامًا.
وافَق المستخدم صراحة على تنزيل وتجهيز qpdf وTesseract واللغات و7-Zip محليًا للاختبار في21 أكتوبر2026. الجملة السابقة عن عدم تنزيل برامج تصف مرحلة20 أكتوبر فقط؛ لا تنطبق على هذه الإضافة.

