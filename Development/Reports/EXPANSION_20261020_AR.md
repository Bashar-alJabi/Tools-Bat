# تقرير توسعة tOOls Bat — 2026-10-20

**النتيجة: 55 أداة سابقة + 30 أداة جديدة فعلية = 85 أداة.** بقي التنظيم Tools / System / Development، ولكل أداة جديدة BAT وPS1 محلي وMD مستقل وInput وOutput، والمجلدات الخاصة عند الحاجة. لم تُضف حزمة خارجية أو إطار تشغيل جديد.

الفرع **codex-improvements** فقط. بدأ العمل بحالة Git نظيفة عند `3d9668f`. حُفظت الدفعة الأولى في commit `346f8da`، ثم أُكملت الدفعة الثانية واختباراتها. لا دمج في main ولا force push أو تعديل للتاريخ السابق.

## الأدوات الثلاثون المنفذة

الدفعة الأولى تضم1–15، والثانية16–30. كل رابط يفتح الدليل الخاص بالأداة، بما فيه الإعدادات والأسماء الناتجة والأخطاء والقيود.

| # | الأداة | الوظيفة الفعلية |
|---:|---|---|
| 1 | [Image Duplicates](<../../Tools/IMG/Image Duplicates/Image Duplicates.md>) | مجموعات تشابه dHash ودرجاته مع تمييز SHA-256 المطابق بالبايتات؛ بلا حذف |
| 2 | [Image to PDF](<../../Tools/IMG/Image to PDF/Image to PDF.md>) | صور مرتبة إلى PDF، وA4 عمودي/أفقي أو أبعاد الصورة |
| 3 | [Image Compare](<../../Tools/IMG/Image Compare/Image Compare.md>) | تقرير RMSE وصورة فروق، مع رفض الأبعاد غير المتوافقة |
| 4 | [Image Collage](<../../Tools/IMG/Image Collage/Image Collage.md>) | تخطيطان بصورة رئيسية كبيرة وصورتين صغيرتين، وفواصل وخلفية وحجم |
| 5 | [Image Auto Orient](<../../Tools/IMG/Image Auto Orient/Image Auto Orient.md>) | تصحيح EXIF فقط؛ نسخ مطابق بالبايتات عندما لا يلزم تصحيح |
| 6 | [Image Color Palette](<../../Tools/IMG/Image Color Palette/Image Color Palette.md>) | ألوان ممثلة وتكراراتها وشريط عينات |
| 7 | [Image Format Report](<../../Tools/IMG/Image Format Report/Image Format Report.md>) | CSV جماعي وتوزيع الصيغ وإجمالي الحجم وأكبر الصور |
| 8 | [Video Merge](<../../Tools/VID/Video Merge/Video Merge.md>) | دمج مرتب؛ نسخ مباشر متوافق أو توحيد H.264/AAC والدقة وFPS وSAR |
| 9 | [Video Screenshot at Time](<../../Tools/VID/Video Screenshot at Time/Video Screenshot at Time.md>) | لقطة من وقت محدد بالثواني، مع التحقق من المدة |
| 10 | [Video Watermark](<../../Tools/VID/Video Watermark/Video Watermark.md>) | شعار ثابت بموضع وقياس وشفافية؛ مراعاة دوران عرض الفيديو |
| 11 | [Video Subtitles Burn](<../../Tools/VID/Video Subtitles Burn/Video Subtitles Burn.md>) | حرق SRT/ASS، وفحص libass ودعم العربية وفق الخطوط |
| 12 | [Video Extract Subtitles](<../../Tools/VID/Video Extract Subtitles/Video Extract Subtitles.md>) | استخراج ترجمة نصية أو نسخ صورية إلى حاوية مناسبة، دون OCR |
| 13 | [Video Add Subtitle Track](<../../Tools/VID/Video Add Subtitle Track/Video Add Subtitle Track.md>) | ترجمة اختيارية في MKV مع نسخ الفيديو والصوت |
| 14 | [Video Remove Black Bars](<../../Tools/VID/Video Remove Black Bars/Video Remove Black Bars.md>) | تقرير وأبعاد ولقطة افتراضيًا؛ القص الفعلي بعد APPLY فقط |
| 15 | [Video Audio Sync](<../../Tools/VID/Video Audio Sync/Video Audio Sync.md>) | تقديم أو تأخير الصوت، مع صمت تعويضي وحفظ مدة الفيديو |
| 16 | [Audio to Video](<../../Tools/VID/Audio to Video/Audio to Video.md>) | تسجيل صوتي إلى MP4 بخلفية سوداء أو صورة ثابتة |
| 17 | [Video Metadata Report](<../../Tools/VID/Video Metadata Report/Video Metadata Report.md>) | تقارير مكتبة فيديو ومساراتها، وتوزيع الترميزات والدقات وFPS ومجموع المدد |
| 18 | [Audio Remove Silence](<../../Tools/AUD/Audio Remove Silence/Audio Remove Silence.md>) | صمت الأطراف افتراضيًا أو الفجوات الداخلية بعتبة ومدة |
| 19 | [Audio Split by Silence](<../../Tools/AUD/Audio Split by Silence/Audio Split by Silence.md>) | تقسيم عند منتصف الفواصل مع حد أدنى للمقاطع وفهرس أزمنة |
| 20 | [Audio Volume Report](<../../Tools/AUD/Audio Volume Report/Audio Volume Report.md>) | قياس Mean/Peak dBFS وLUFS وTrue Peak وLRA، دون تعديل |
| 21 | [Audio Reverse](<../../Tools/AUD/Audio Reverse/Audio Reverse.md>) | عكس العينات الصوتية إلى WAV، مع حد للمدة والذاكرة |
| 22 | [PDF Rotate Pages](<../../Tools/PDF/PDF Rotate Pages/PDF Rotate Pages.md>) | تدوير صفحات مختارة90/180/270 مع حفظ الترتيب |
| 23 | [PDF Extract Pages](<../../Tools/PDF/PDF Extract Pages/PDF Extract Pages.md>) | استخراج صفحات ونطاقات مثل3,1 أو2,5,7-10 بالترتيب المطلوب |
| 24 | [PDF Reorder Pages](<../../Tools/PDF/PDF Reorder Pages/PDF Reorder Pages.md>) | عكس المستند أو ترتيب جميع صفحاته مرة واحدة؛ رفض النقص والتكرار |
| 25 | [PDF Metadata Cleaner](<../../Tools/PDF/PDF Metadata Cleaner/PDF Metadata Cleaner.md>) | إفراغ حقول وصفية محددة وحذف تواريخ Info وXMP المولد، دون ادعاء تنقيح مضمون |
| 26 | [Batch Rename](<../../Tools/UTI/Batch Rename/Batch Rename.md>) | أنماط ومعاينة وتصادمات؛ نسخ افتراضي، وتعديل الأصول بموافقة ونسخة احتياطية |
| 27 | [Find Large Files](<../../Tools/UTI/Find Large Files/Find Large Files.md>) | أكبر الملفات وأحجام المجلدات التراكمية في Input أو نطاق قراءة يحدده المستخدم |
| 28 | [Empty Folders Report](<../../Tools/UTI/Empty Folders Report/Empty Folders Report.md>) | جرد المجلدات الفارغة مباشرة دون حذفها |
| 29 | [Text Find and Replace](<../../Tools/UTI/Text Find and Replace/Text Find and Replace.md>) | معاينة واستبدال حرفي في نسخ بعد WRITE، مع حفظ الترميز المدعوم |
| 30 | [CSV to JSON](<../../Tools/UTI/CSV to JSON/CSV to JSON.md>) | CSV إلى JSON نصي مع اقتباسات وأسطر متعددة، وعكس محدود يحفظ المعنى والدقة |

التوزيع النهائي حسب الفئات: IMG21، VID27، AUD10، PDF9، UTI16، NET2.

## التكرارات والقرارات

- استُبدلت **Image Add Text** بـ**Image Color Palette**: Image Watermark الموجودة توفر أصلًا النص والحجم والمواضع؛ إضافة اسم آخر لن تنشئ وظيفة جديدة كافية.
- استُبدلت **Folder Sync Preview** بـ**Empty Folders Report**: Folder Compare الموجودة تقارن الجديد والمختلف والمفقود بالبصمة دون نسخ أو حذف.
- احتُفظ بـImage Collage لأنها ليست شبكة Contact Sheet المنتظمة، وبـScreenshot at Time لأن Thumbnail القديمة لا تتيح وقتًا مخصصًا، وبـBatch Rename لأن أنماطها ومعاينتها وتأكيدها تختلف عن الترقيم الثابت في Rename Copies.
- تقريري الصور والفيديو الجديدين يجمعان إحصاءات وتحليلًا للمجموعة، بخلاف Image Info وMedia Info الفرديين. PDF Extract يختار صفحات، وPDF Reorder يشترط المستند كاملًا دون إسقاط أو تكرار.

تفاصيل الوظائف والخيارات في [خطة التوسعة](expansion-20261020-plan.json)، ومراجعة الـ55 وبصماتها في [سجل الموجود](expansion-20261020-existing-review.json).

## المحافظة على المشروع والاعتمادات

تحققت بصمات **80 ملف BAT/PS1** من الأدوات القديمة دون تغيير، وبقيت جميع المسارات الـ663 المتتبعة عند البداية موجودة. التعديلات على الأدلة القديمة تصلح عمق إشارات System فقط. Core وArchives وDownload وToolRunner وNewTool وpackages.json بقيت دون تعديل في هذه التوسعة. [سجل الحفاظ](expansion-20261020-retention.json) يوثق ذلك.

حُفظت سجلات النتائج السابقة في Development/tests/recorded/pre-expansion-20261020 قبل تحديث نتائج التشغيل. السجلات الأولى التي أظهرت إخفاقات محفوظة أيضًا، مع سجلات إعادة الاختبار؛ لم تُحذف نسخ أصلية أو بيانات مستخدم أو توزيعات dist قديمة. ملفات الوسائط التجريبية والبرامج المنسوخة للاختبار ومخرجاتها داخل المساحات المستبعدة من Git.

**لا اعتماد خارجي جديد.** الأدوات تستخدم FFmpeg/FFprobe وImageMagick وGhostscript وWindows PowerShell/.NET الموجودين. Microsoft.VisualBasic الخاص بقراءة CSV جزء من .NET Framework، وليس تنزيلًا أو مكتبة مضافة للمشروع.

START_HERE يعرض الآن85 أداة واعتماداتها، ويكشف النسخ المحلية أولًا ثم المثبتة، ويضيف فحص subtitles/libass عند توفر FFmpeg. غياب المرشح يجعل الجاهزية جزئية ويحدد الأداة المتأثرة. لم يتغير وضع Ghostscript: تنزيل المثبت والتحقق منه لا يعني تشغيله أو اكتمال تجهيز جهاز نظيف؛ النسخة المحمولة الكاملة أو الخطوة اليدوية ما زالت مطلوبة عند غياب برنامج متوافق. لم تُنزّل أو تُثبت برامج، ولم تُعدّل PATH العام أوRegistry أوصلاحيات Windows.

## الاختبارات الفعلية والنتائج

نُفذت على Windows10.0.26300.0 وWindows PowerShell5.1.26100.9549، باستخدام البرامج المثبتة: FFmpeg/FFprobe9.0.1 وImageMagick7.1.2-30 وGhostscript10.07.1.

**595 حالة/تحقق مجمع ناجح، صفر فشل قائم**. هذه ليست عدد أوامر التنفيذ؛ بعض الحالات تجمع help/check والمعالجة والتكرار وعدة تأكيدات محتوى. لا تُجمع إعادة التشغيل نفسها مرتين في العدد النهائي.

| المجموعة | الحالات الناجحة | السجل داخل Development/tests |
|---|---:|---|
| الأدوات الأساسية وخياراتها والأرشيفات والتنزيلات المصطنعة | 123 | results.json |
| الأدوات الـ25 السابقة مع الحالات الموسعة | 127 | improvements-All-results.json |
| مقارنة القوائم الأصلية وتغطية الأدلة | 23 | original-comparison-results.json |
| بنية المشروع وPowerShell وأرشيف الأصل والعزل | 6 | verification-results.json |
| التوزيع وبصماته وتضمين برامج محلية اختياريًا | 5 | distribution-results.json |
| مشغلات الجذر ورفض التجهيز الاختياري | 5 | root-bat-results.json |
| الحالات الحدية السابقة | 9 | edge-results.json |
| برامج محلية مع تعطيل اكتشاف برامج النظام | 6 | local-portable-results.json |
| الأدوات الجديدة الثلاثون | 145 | expansion-All-results.json مع إعادة الفحص المركزة للأجزاء المحسنة |
| خيارات غير افتراضية وحدود وتصادمات وتأكيدات | 45 | expansion-options-final-results.json ومصادره المسجلة |
| فك ZIP النهائي وBAT85 وSTART_HERE مرتين وروابط MD وعينات قديمة وجديدة | 101 | reorganization-results.json |

فُحصت النتائج نفسها: صفحات PDF وترتيب نصوصها، وزوايا التدوير بمقارنة بكسلات مرجعية90/180/270، ونسخ الصوت المعكوس عينة بعينة، ومدة المقاطع وحدود الصمت ومستويات الصوت، وأبعاد الصور والفروق ولوحات الألوان وإحصاءات التقارير، وتطابق لقطة وقت محدد، ونسخ الفيديو دون إعادة ترميز عند إضافة ترجمة، وبكسلات الشعار والترجمة. فُحصت عينة الترجمة العربية بصريًا أيضًا.

جرى اختبار القص بعد APPLY ورفضه، ورفض إعادة تسمية الأصول ثم تطبيقها على **عينات معزولة فقط** مع التحقق من النسخة الاحتياطية، وحفظ UTF-16 والأسطر المتعددة والاقتباسات والأرقام الكبيرة كنصوص. استُخدمت مسارات عربية ومسافات و`& ! % []`، وأسماء Unicode، وتشغيل BAT من مجلد عمل مختلف، ومدخلات فارغة وتالفة، واعتمادات مفقودة، وتكرار التشغيل وبصمات الأصول والمخرجات السابقة.

### الأخطاء التي كُشفت وأُصلحت

- معيار قياس الترجمة لم يلائم عينة96×64؛ استُخدمت عينة640×360 وأعيدت جميع سيناريوهات الأداة، دون تغيير خوارزمية الحرق لتجاوز الاختبار.
- pdfwrite في البناء المثبت رفض PageList غير المتزايدة. أصبح الاستخراج وإعادة الترتيب يصدران الصفحات إلى ملفات عمل ثم يدمجانها بالترتيب الصريح. اختُبرت3,1 و3,1,2 والعكس الكامل. [توثيق اختيار الصفحات](https://ghostscript.readthedocs.io/en/gs10.05.1/Use.html#spagelist-pageranges) يشرح واجهة Ghostscript، والتحقق هنا اعتمد التنفيذ الفعلي أيضًا.
- silenceremove لم يطبق الفاصل ذي المدة الحدية كما توقع القياس؛ أزيل الاعتماد عليه في الوضع الداخلي واستُخدمت فترات silencedetect نفسها مع هامش0.1ثانية.
- شُدد توافق الدمج ليشمل خصائص البكسلات والعرض والمسارات وAAC في النسخ المباشر إلىMP4؛ اختُبرت مصادرPCM غير المتوافقة وSAR غير المربع. حُسبت أبعاد القص والشعار بعد دوران العرض، واختُبرت ملفات بعلامة دوران90°.
- صُححت عينات وقياسات الاختبار نفسها عند الحاجة، بما فيها امتداد الملف التالف لأداة تنتج فيديو من صوت، ومتغير فحص المستطيلات؛ السجلات الأولى بقيت للمراجعة.

[ملخص النتائج والبصمات](expansion-20261020-test-summary.json) يربط مجموعات الاختبار النهائية. السجلات الجديدة تنشر جذر المشروع كمرجع رمزي عند الحاجة؛ العينات الثنائية الثقيلة لا تُرفع.

## BUILD_DISTRIBUTION والتسليم

المشغل الحالي يستخدم الفهرس تلقائيًا ويصدر85 أداة. حُدث إنشاء المجلدات الفارغة الخاصة بـImage Compare وSubtitles وPicture. اختُبر بناء نظيف، وإعادة رفض وجهة موجودة، وبصمات الملفات، وتضمين شجرة Ghostscript محلية كاملة في نسخة اختبار منفصلة.

الملف النهائي المحلي:

```text
dist/tOOls Bat 85 20261020.zip
Size: 499647 bytes
SHA256: 57070931232EF2102DA188210886017633414394BDD83A868BC53F4A23849F44
```

يحوي Tools وSystem وSTART_HERE وBUILD_DISTRIBUTION وأدلتها وREADME وdistribution-manifest.json؛ يسجل manifest258 ملفًا، عدا نفسه، وتبقى مجلدات Input/Output والمجلدات الخاصة فارغة. لا Development أوGit أوأرشيف أصل أوبيانات مدخلات ومخرجات شخصية أوتنزيلات مخبأة. لا يشمل البرامج الخارجية افتراضيًا؛ تضمين System/Bin خيار منفصل مع التزامات الترخيص.

فك ZIP كاملًا على جهاز Windows متوافق قابل للكتابة، ثم شغّل START_HERE. احتفظ بـTools وSystem والملفات الأساسية وmanifest معًا. ملف BAT منفردًا لا يكفي لنقل المعالجة والوظائف المشتركة. انقل مشروعك كاملًا بصورة منفصلة إذا أردت الاحتفاظ بمدخلاتك ومخرجاتك الشخصية؛ ZIP النظيف يستبعدها.

## القيود والاختبارات غير المنفذة

- dHash ترشيح تقريبي وقد يعطي تشابهًا كاذبًا، خصوصًا لصور متجانسة؛ الدرجة ليست احتمالًا أو ضمان تطابق.
- دعم الترميز والصيغ والخطوط يعتمد على بناء البرامج. اختُبر حرقSRT العربي والنصوص المستخرجة/المضافة؛ لم تتوفر عينات فعلية لكل تنويعاتASS أوPGS/VobSub/DVB والصيغ النادرة. مسار الترجمة الصورية لا يؤديOCR ولا يدعي استخراج نص منها.
- أدوات PDF تعيد كتابة المستند وقد تفقد نماذج أو مرفقات أوصلاحية توقيعات. منظف metadata ليس Redaction ولا ضمان إزالة آثار حساسة؛ Producer يبقى.
- إزالة الصمت قد تعتبر كلامًا هادئًا صمتًا، والقص الأسود تقريبي. عكس الصوت محدود600ثانية وذاكرة تقديرية256MB. حدود الأعداد والمسارات وبقية القيود موثقة في MD لكل أداة؛ الحد المحافظ المعتاد240محرفًا للملف و200لبعض مجلدات النتائج.
- JSON إلىCSV محدود بالكائنات المسطحة ذات القيم النصية، ويرفض الأرقام وnull والبنية المتداخلة عمدًا بدل تقريبها أو تغيير معناها.
- لم يُختبر Windows10 على جهاز مستقل أوARM64/x86 أوUSB فعلي أوجهاز ثانٍ؛ النقل اختُبر محليًا بالنسخ وفك الأرشيف إلى مواقع مختلفة. لم تُنزّل الحزم الحقيقية أوتُثبت على جهاز نظيف. محاكاة التنزيل والفساد والانقطاع واختبارات الاعتمادات المحلية باقية وتعمل.
- لم تُنفذ عمليات حساسة على بيانات المستخدم أوالنظام، ولم تُحذف توزيعات dist القديمة في هذه المهمة. لا فشل وظيفي قائم في السيناريوهات المختبرة.

فرع المراجعة: [codex-improvements على GitHub](https://github.com/Bashar-alJabi/Tools-Bat/tree/codex-improvements). main محفوظ دون دمج تلقائي.
