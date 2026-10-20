# tOOls Bat

مجموعة أدوات Windows قابلة للنقل: **70 أداة** للصور والفيديو والصوت وPDF والملفات والشبكة، إضافة إلى `START_HERE.bat` للتجهيز. الأسماء والمجلدات والقوائم الأصلية محفوظة. كل أداة لها MD مستقل؛ الأدوات الـ25 الجديدة تضع المعالجة في PS1 داخل مجلدها وتشارك وظائف المسارات والأمان واكتشاف البرامج فقط.

## التنظيم

```text
Tools/IMG, VID, AUD, PDF, UTI, NET    أدوات المستخدم وأدلتها ومدخلاتها ونتائجها
System/Shared                      ملفات التشغيل المشتركة
System/Bin                         توزيعات البرامج المحلية الكاملة
System/Docs                        الاعتمادات ودليل النقل
System/Downloads                   ذاكرة تنزيل اختيارية، لا تدخل التوزيع
Development/tests                  الاختبارات والسجلات والعينات المحفوظة
Development/Original               أرشيف النسخة الأصلية وأدوات الاسترجاع
Development/Reports                تقارير المراجعة والتطوير
```

احتفظ بمجلد الأداة كاملًا مع System عند النقل. ملفات التطوير تبقى في المستودع وتُستبعد من ZIP النظيف. لم تتغير القوائم أو مواضع Input وOutput داخل مجلدات الأدوات.

## البداية

1. شغّل `START_HERE.bat`. يعرض Windows والمعمارية والبرامج المتاحة ومساراتها والأدوات التي تحتاجها.
2. إذا كانت البرامج موجودة يمكنك البدء مباشرة. اختر تنزيل البرامج التي تحتاجها فقط؛ الإجابة الافتراضية هي **لا**.
3. ضع الملفات داخل مجلد `Input` التابع للأداة المطلوبة، ثم شغّل ملف BAT واختر الإعدادات.
4. ستجد النتائج داخل `Output` التابع للأداة نفسها.

لا تحتاج صلاحية Administrator. يتطلب التشغيل Windows 10 أو Windows 11 وWindows PowerShell 5.1 الموجود معهما. ملفات BAT تستدعي PowerShell المحلي دون تغيير سياسة التنفيذ المحفوظة في Windows.

لا تُحذف المدخلات ولا تُستبدل النتائج السابقة. عند وجود نتيجة بالاسم نفسه تُتخطى، بما في ذلك ملفان أصليان لهما الاسم الأساسي نفسه وامتدادان مختلفان. احتفظ بالنتيجة السابقة خارج Output أو غيّر اسمها إذا أردت إنشاء نتيجة جديدة.

## الأدوات الأصلية

| ملف BAT داخل مجلده | الوظيفة | الاعتماد | إعداد `--defaults` |
|---|---|---|---|
| Tools/IMG/Image Background Color Remover/Background Color Remover.bat | جعل لون خلفية موحد شفافًا | ImageMagick | أبيض، سماحية 10%، PNG |
| Tools/IMG/Image Compression/Image Compression.bat | ضغط الصور بنفس الصيغة | ImageMagick | جودة 85؛ PNG ضغط 9؛ TIFF ضغط ZIP |
| Tools/IMG/Image Converter/Image Convert.bat | تحويل صيغة الصور | ImageMagick | JPG جودة 85، خلفية بيضاء للشفافية |
| Tools/IMG/Image Crop/Image Crop.bat | قص مركزي حسب النسبة | ImageMagick | 1:1 |
| Tools/IMG/Image Enhance/Image Enhance.bat | تكبير وزيادة الحدة | ImageMagick | 200%، حدة متوسطة |
| Tools/IMG/Image Grid/Image Contact Sheet.bat | لوحة صور مع أسماء الملفات | ImageMagick | 4 أعمدة، صور مصغرة 300 بكسل |
| Tools/IMG/Image Metadata Cleaner/Image Metadata Cleaner.bat | إزالة البيانات التي يحذفها `-strip` | ImageMagick | نفس الصيغة |
| Tools/IMG/Image Resize/Image Resize.bat | تصغير مع حفظ النسبة | ImageMagick | حد 1920×1080 دون تكبير |
| Tools/IMG/Image Watermark/Image Watermark.bat | علامة نصية أو شعار حتى 9 مواضع | ImageMagick | نص Copyright، حجم 64، شفافية 60%، أسفل اليمين |
| Tools/PDF/Compress PDF/Compress PDF.bat | إعادة كتابة PDF بضغط مختار | Ghostscript | Ebook |
| Tools/VID/Video  Compression/Compress Video.bat | ضغط H.264 أو HEVC | FFmpeg | H.264، CRF 23، AAC 128k؛ NVENC إذا نجحت تجربته وإلا CPU |
| Tools/VID/Video - Audio/Convert Audio.bat | تحويل صوت **الفيديو** إلى AAC مع نسخ الفيديو | FFmpeg | AAC 192k، MP4 |
| Tools/VID/Video - Audio/Extract Audio.bat | استخراج الصوت من الفيديو | FFmpeg | MP3 VBR q=2 |
| Tools/VID/Video - Audio/Increase Volume.bat | رفع صوت الفيديو | FFmpeg | +6 dB، نسخ الفيديو، AAC 192k |
| Tools/VID/Video - Audio/Merge Audio.bat | مزج الصوت الأصلي بصوت مضاف | FFmpeg | المضاف 50%، merged.mp4 |
| Tools/VID/Video - Audio/Normalize Audio.bat | موازنة شدة الصوت | FFmpeg | loudnorm بمرور واحد، نسخ الفيديو |
| Tools/VID/Video - Audio/Remove Audio.bat | حذف الصوت من نسخة جديدة | FFmpeg | نسخ مسار الفيديو إلى MP4 |
| Tools/VID/Video - Audio/Replace Audio.bat | استبدال الصوت بصوت خارجي | FFmpeg | AAC 192k، أقصر مدة، replaced.mp4 |
| Tools/VID/Video FPS Converter/Video FPS Converter.bat | تحويل معدل الإطارات | FFmpeg | 30 FPS، H.264 CRF 18 |
| Tools/VID/Video Resolution Converter/Video Resolution Converter.bat | تغيير دقة الفيديو مع حفظ النسبة | FFmpeg | حتى 1080p، H.264 CRF 16؛ يمكن تكبير فيديو أصغر |
| Tools/VID/Video Speed/Video Speed.bat | تغيير سرعة الفيديو والصوت | FFmpeg | 1.5×، مع حفظ Pitch الصوت |

مجلد `Video  Compression` يحتوي **مسافتين** في اسمه الأصلي؛ لم يتغير الاسم.

أدوات `Tools/VID/Video - Audio` السبع تشترك في Input وOutput وفق التنظيم الأصلي. بعض نتائجها تحمل الاسم نفسه؛ انقل نتيجة العملية السابقة خارج Output قبل تشغيل عملية أخرى على المدخل نفسه، حتى لا تُتخطى بسبب وجودها.

## الأدوات التسع المضافة سابقًا

| الأداة | الاستخدام والنتيجة | الاعتماد |
|---|---|---|
| Tools/AUD/Audio Converter | تحويل ملفات الصوت الفعلية إلى MP3/WAV/FLAC/M4A/Opus. الافتراضي MP3 VBR q=2 | FFmpeg |
| Tools/VID/Video Thumbnail | أول إطار من كل فيديو إلى PNG دون تعديل الفيديو | FFmpeg |
| Tools/PDF/Merge PDF | دمج PDF حسب ترتيب أسماء الملفات في merged.pdf؛ استخدم بادئات 001 و002 لتحديد الترتيب | Ghostscript |
| Tools/UTI/Media Info | تقرير JSON لكل ملف: المسارات والترميزات والأبعاد والمدة والبيانات الوصفية | FFprobe |
| Tools/UTI/File Hashes | إنشاء Output/hashes.csv ببصمات SHA-256 لكل شجرة Input، والتحقق لاحقًا من الملفات والبصمات ووجود ملفات إضافية | مكونات Windows فقط |
| Tools/UTI/Duplicate Finder | تقرير duplicates.csv بالأحجام والبصمات المتساوية؛ **لا يحذف شيئًا** | مكونات Windows فقط |
| Tools/UTI/File Inventory | جرد inventory.csv بالمسار النسبي والامتداد والحجم وتاريخ التعديل UTC | مكونات Windows فقط |
| Tools/UTI/ZIP Backup | ضغط شجرة Input في backup.zip؛ يشمل الملفات المخفية والمجلدات الفارغة ويتجاوز الروابط | .NET المدمج |
| Tools/UTI/ZIP Extract | استخراج كل ZIP في مجلد مستقل جديد باسم الملف مع `.extracted`؛ يرفض المسارات الخارجة والروابط والأسماء غير الآمنة | .NET المدمج |

كل أداة جديدة موجودة داخل مجلدها بملف BAT يحمل اسمها ومجلدي Input وOutput.

## الدفعة الجديدة: 25 أداة مستقلة في الاستخدام

| BAT وMD داخل مجلد الأداة | الوظيفة | الاعتماد |
|---|---|---|
| [Image Rotate](<Tools/IMG/Image%20Rotate/Image%20Rotate.md>) | تدوير الصور | ImageMagick |
| [Image Flip](<Tools/IMG/Image%20Flip/Image%20Flip.md>) | عكس الصور | ImageMagick |
| [Image Grayscale](<Tools/IMG/Image%20Grayscale/Image%20Grayscale.md>) | صور بتدرج رمادي | ImageMagick |
| [Image Border](<Tools/IMG/Image%20Border/Image%20Border.md>) | إطار حول الصور | ImageMagick |
| [Image Info](<Tools/IMG/Image%20Info/Image%20Info.md>) | معلومات الصور | ImageMagick |
| [Video Trim](<Tools/VID/Video%20Trim/Video%20Trim.md>) | اقتطاع مقطع فيديو | FFmpeg |
| [Video Rotate](<Tools/VID/Video%20Rotate/Video%20Rotate.md>) | تدوير الفيديو | FFmpeg |
| [Video To GIF](<Tools/VID/Video%20To%20GIF/Video%20To%20GIF.md>) | تحويل فيديو إلى GIF | FFmpeg |
| [Video Remux](<Tools/VID/Video%20Remux/Video%20Remux.md>) | تغيير حاوية الفيديو | FFmpeg |
| [Video Frames](<Tools/VID/Video%20Frames/Video%20Frames.md>) | استخراج إطارات فيديو | FFmpeg |
| [Audio Trim](<Tools/AUD/Audio%20Trim/Audio%20Trim.md>) | اقتطاع الصوت | FFmpeg |
| [Audio Normalize](<Tools/AUD/Audio%20Normalize/Audio%20Normalize.md>) | موازنة شدة الصوت | FFmpeg |
| [Audio Fade](<Tools/AUD/Audio%20Fade/Audio%20Fade.md>) | تدرج بداية ونهاية الصوت | FFmpeg |
| [Audio Channels](<Tools/AUD/Audio%20Channels/Audio%20Channels.md>) | تغيير عدد قنوات الصوت | FFmpeg |
| [Audio Concatenate](<Tools/AUD/Audio%20Concatenate/Audio%20Concatenate.md>) | وصل المقاطع الصوتية | FFmpeg |
| [PDF Split](<Tools/PDF/PDF%20Split/PDF%20Split.md>) | تفكيك صفحات PDF | Ghostscript |
| [PDF To Images](<Tools/PDF/PDF%20To%20Images/PDF%20To%20Images.md>) | صفحات PDF إلى صور | Ghostscript |
| [PDF Text](<Tools/PDF/PDF%20Text/PDF%20Text.md>) | استخراج نص PDF | Ghostscript |
| [Rename Copies](<Tools/UTI/Rename%20Copies/Rename%20Copies.md>) | ترقيم نسخ الملفات | Windows/.NET |
| [Sort Copies](<Tools/UTI/Sort%20Copies/Sort%20Copies.md>) | تنظيم نسخ الملفات | Windows/.NET |
| [Text Encoding](<Tools/UTI/Text%20Encoding/Text%20Encoding.md>) | تحويل ترميز النص | Windows/.NET |
| [Folder Compare](<Tools/UTI/Folder%20Compare/Folder%20Compare.md>) | مقارنة مجلدين | Windows/.NET |
| [JSON Format](<Tools/UTI/JSON%20Format/JSON%20Format.md>) | تنسيق JSON | Windows/.NET |
| [Network Info](<Tools/NET/Network%20Info/Network%20Info.md>) | معلومات الشبكة المحلية | Windows/.NET |
| [Ping Host](<Tools/NET/Ping%20Host/Ping%20Host.md>) | فحص استجابة عنوان | Windows/.NET |

داخل كل مجلد: BAT للتشغيل، وPS1 واضح للمعالجة الخاصة بالأداة، وMD مفصل، وInput وOutput. الأدوات الجديدة لا تمر عبر ToolRunner أوNewTool؛ تستخدم Core للأمان والملفات فقط. لا توجد حزم PowerShell إضافية.

## تشغيل متقدم

كل BAT تابع لأداة يدعم `--help` و`--check` و`--defaults`. عند التشغيل التلقائي اضبط `TB_NO_PAUSE=1` لتجاوز الانتظار الأخير. `START_HERE.bat --check` يفحص فقط ولا يطلب تنزيلًا.

```bat
set "TB_NO_PAUSE=1"
"C:\My Tools\tOOls Bat\START_HERE.bat" --check
"C:\My Tools\tOOls Bat\IMG\Image Resize\Image Resize.bat" --defaults
"C:\My Tools\tOOls Bat\UTI\File Hashes\File Hashes.bat" --verify
```

المثال يستخدم مسارًا توضيحيًا؛ السكربتات تكتشف موضعها بواسطة `%~dp0` ولا تخزّن هذا المسار. يفضّل تشغيلها مباشرة دون `CALL` ثانٍ يعيد تفسير `%` في أسماء المسارات. إذا كانت عملية cmd الأم مفعّلًا فيها Delayed Expansion، أوقفه قبل تمرير مسار يحتوي `!`.

أكواد الخروج: `0` نجاح أو لا مدخلات أو تخطي نتيجة موجودة؛ `1` فشل معالجة ملف أو عدم تطابق بصمة؛ `2` إعداد/مدخل غير صالح أو فشل تشغيل عام؛ `3` اعتماد مفقود أو تجهيز جزئي. الأدوات الجديدة ترجع `2` عند تعذر تحميل اعتمادها. لا تعتمد على قراءة كلمة SUCCESS وحدها عند الأتمتة.

## الاعتمادات والتجهيز

التفاصيل والمصادر والتراخيص في [سجل الاعتمادات](<System/Docs/DEPENDENCIES.md>). ترتيب الاكتشاف:

1. نسخة متوافقة داخل `System/Bin/ffmpeg` أو `System/Bin/imagemagick` أو `System/Bin/ghostscript`، مع البحث داخل المجلد الفرعي `bin` إن وجد.
2. نسخة قابلة للتشغيل في النظام؛ يفحص PATH ومواضع ImageMagick/Ghostscript المعتادة داخل Program Files.
3. عرض تنزيل اختياري لإصدار ثابت، مع التحقق من SHA-256 قبل الاستخراج أو التجهيز.

احتفظ **بالتوزيعة كاملة** داخل `System/Bin`، بما فيها DLL والموارد وملفات الترخيص. لا يكفي نسخ EXE منفردًا لبرنامج يحتاج موارد إضافية. لا تضف ffprobe إلى مجلد مستقل؛ يأتي مع FFmpeg.

التنزيل التلقائي المتاح حاليًا لمعمارية x64. للأنظمة ARM64/x86 استخدم توزيعة متوافقة محلية أو مثبتة يدويًا من المصدر الرسمي. استخراج ImageMagick بصيغة 7z يحتاج `tar.exe` المدمج مع إصدارات Windows الحديثة؛ إذا غاب أو لم يدعم الأرشيف، يعطي البرنامج إرشاد الاستخراج اليدوي دون تنزيل أداة إضافية.

**Ghostscript:** المصدر الرسمي المتحقق منه يوفر مثبت Windows. يستطيع START_HERE تنزيله والتحقق منه فقط، ولا يشغّله. يمكنك تثبيته بنفسك، أو تجهيز شجرة محلية كاملة ومتوافقة ومرخصة داخل `System/Bin/ghostscript`. إعادة الفحص ستوضح أن PDF ما زال غير جاهز إلى حين ذلك.

في وضع Offline تعمل جميع الأدوات التي تتوفر اعتماداتها. يمكن نسخ توزيعات البرامج يدويًا إلى `System/Bin` ثم إعادة الفحص. الملفات المنزلة الصحيحة تبقى في `System/Downloads` لإعادة الاستخدام، وتُنظّف الملفات الجزئية التي أنشأها مدير التنزيل بنفسه. إذا كان أرشيف مخبأ تالفًا أو مجلد اعتماد موجودًا لكنه غير صالح، يُحفظ دون استبدال ويُطلب منك نقله أو إصلاحه يدويًا ثم إعادة المحاولة.

## الحدود العملية

- المدخلات المباشرة فقط للصور والوسائط وPDF؛ أدوات الجرد والبصمات والتكرارات والنسخ الاحتياطي تعمل على شجرة Input. جميعها تتجاوز الروابط وJunctions.
- يدعم FFmpeg الصيغ الموجودة أصلًا: MP4/MOV/MKV/AVI/M4V/WebM، وقد يفشل نسخ ترميز قديم إلى MP4. لا تُحوّل الأداة الفيديو تلقائيًا عند اختيار وظيفة النسخ.
- الاستبدال والمزج يحتاجان فيديو واحدًا وصوتًا واحدًا بالضبط؛ الغموض يُرفض. المزج والتحويل ورفع/موازنة الصوت والاستخراج تتطلب مسار صوت موجودًا. السرعة وFPS والدقة والضغط تدعم فيديو صامتًا.
- ملفات الصور متعددة الإطارات تُحفظ عند إخراج GIF/WebP/TIFF. التحويل إلى صيغة صورة ثابتة والعلامة المائية متعددة الإطارات يرفضان العملية لتجنب فقد صفحات/إطارات بصمت. Contact Sheet يستخدم الإطار الأول صراحة.
- النص التفاعلي للعلامة المائية حتى 300 محرف؛ يرفض محارف تفسير cmd/ImageMagick مثل `" % ! & | < > ^ @ [ ] { } \` بدل تنفيذها. أسماء الملفات العربية والمحارف الخاصة لا تمر عبر أوامر shell للمعالجة.
- إزالة metadata باستخدام ImageMagick تعيد ترميز الصورة؛ قد يتغير ضغط JPEG أو عرض اللون/الاتجاه عند حذف ICC/EXIF. الضغط قد ينتج ملفًا أكبر حسب المحتوى. راجع النتيجة بصريًا قبل الاعتماد عليها.
- إعادة كتابة PDF قد تغير خصائص النماذج أو التواقيع الرقمية؛ النتائج نسخ مستقلة. المزج ليس محرر PDF تفاعليًا.
- حد المسار المدعوم المحافظ 240 محرفًا؛ المسارات الأطول تُرفض أو تعطي خطأ واضحًا دون تغيير سياسة Windows. اختر مجلدًا أقصر عند الحاجة.
- الملفات الكبيرة تُقرأ على دفعات للحساب والضغط. يلزم مساحة للنتيجة وملفات العمل؛ يفحص البرنامج مساحة تقريبية بثلاثة أمثال حجم المدخل وبحد أدنى 16 MB. قد يتطلب فك صورة شديدة الضغط مساحة أكبر؛ فشل العملية لا يُنشر كنتيجة ناجحة.
- ZIP غير المشفر فقط، وبحد استخراج 20 GB و100000 عنصر. النسخ الاحتياطي يحفظ المحتوى وبنية الأسماء؛ ليس نسخة نظام أو حفظًا لصلاحيات NTFS وAlternate Data Streams. CSV بصيغة UTF-8، وJSON لمعلومات الوسائط قد يحتوي معلومات شخصية أصلًا مضمنة في الملف.

## نقل المشروع والاسترجاع

انقل Tools وSystem كاملين مع START_HERE.bat وSTART_HERE.md وREADME.md؛ وأبقِ BUILD_DISTRIBUTION.bat وBUILD_DISTRIBUTION.md لإعادة إنتاج نسخة نظيفة؛ يمكن وضعه على USB أو قرص آخر أو مسار به مسافات. شغّل START_HERE على الجهاز الآخر؛ النسخ المكتشفة من النظام على الجهاز الأول لا تنتقل تلقائيًا معه. لا حاجة للإنترنت عند وجود الاعتمادات محليًا.

`Development/Original/original.zip` هو أرشيف ملفات ما قبل التعديل، و`Development/Original/manifest.json` يسجل البصمات، و`directories.json` يحفظ بنية المجلدات الفارغة. للاسترجاع استخدم السكربت التالي مع **مجلد جديد**؛ يتحقق من البصمات ويرفض وجهة موجودة دون الكتابة فوق Input/Output الحاليين. سجل التحويل التطويري محفوظ داخل `Development/Original` ويرفض إعادة التنفيذ على ملفات معدلة.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\Original\Restore-ToFolder.ps1" -Destination ".\Original-Restored"
```

`Development/tests` يحتوي اختبارات وبيانات تجريبية معزولة؛ لا تحتاج نسخه عند تسليم الأدوات. راجع [التقرير العربي](<Development/Reports/REVIEW_REPORT_AR.md>) و[نتائج الاختبار](<Development/tests/recorded/results.json>). لإعادة الاختبارات باستخدام البرامج المثبتة، شغّل:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Run-Tests.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Test-LocalPortable.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Test-EdgeCases.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Verify-Project.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Test-Improvements.ps1" -Batch ImagesVideo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Test-Improvements.ps1" -Batch AudioPDF
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Development\tests\Test-Improvements.ps1" -Batch FilesNetwork
```

لا تختبر هذه الأوامر على ملفاتك الأصلية؛ الاختبار المرفق يُنشئ مساحته الخاصة داخل `Development/tests/_sandbox` ويحفظها للمراجعة.

## توزيع نظيف ونسخة GitHub

التطوير الحالي على فرع `codex-improvements` للمراجعة؛ لا يُدمج في main تلقائيًا. ملفات النسخة الاحتياطية والاختبارات المرفوعة سابقًا باقية في Git. المجلدات المؤقتة الجديدة Development/tests/_work وDevelopment/tests/_sandbox ومخرجات dist مستبعدة من الإضافات الجديدة؛ الاستبعاد لا يحذف الملفات المتتبعة الموجودة سابقًا. تحفظ .gitattributes المحتوى دون تحويل نهايات الأسطر.

شغّل [BUILD_DISTRIBUTION.bat](<BUILD_DISTRIBUTION.md>) لإنتاج مجلد وZIP نظيفين داخل dist، مع BAT وMD وملفات المعالجة اللازمة ومجلدات Input/Output فارغة. يمكن تضمين توزيعات System/Bin المحلية الكاملة؛ لا تُنسخ البرامج المثبتة أو ملفات المستخدم تلقائيًا. [دليل النقل](<System/Docs/DISTRIBUTION.md>) يشرح التسليم، و[START_HERE](<START_HERE.md>) يشرح التنزيل الموافق عليه وخيار --portable لنسخ توزيعة مثبتة إلى المشروع.

التقارير داخل Development/tests/recorded تحفظ نتائج المرحلة السابقة مع إزالة المسارات الشخصية. التقرير السابق Development/Reports/REVIEW_REPORT_AR.md تاريخي؛ [تقرير الفرع الحالي](<Development/Reports/IMPROVEMENTS_REPORT_AR.md>) يوضح الدفعات والاختبارات الجديدة، و[مقارنة الأصل](<Development/Reports/ORIGINAL_COMPARISON_AR.md>) توضح الحفاظ على التصميم. تحديث النسخة الاحتياطية يتطلب commit وpush، والتوزيع النظيف منفصل عنها.

[تقرير إعادة التنظيم واختبار النقل](Development/Reports/REORGANIZATION_REPORT_AR.md).

## توسعة 2026-10-20 — الدفعة الأولى

- [Image Duplicates](<Tools/IMG/Image Duplicates/Image Duplicates.md>): البحث عن صور متشابهة بصريًا.
- [Image to PDF](<Tools/IMG/Image to PDF/Image to PDF.md>): تحويل الصور إلى مستند PDF.
- [Image Compare](<Tools/IMG/Image Compare/Image Compare.md>): مقارنة صورتين وإظهار اختلافهما.
- [Image Collage](<Tools/IMG/Image Collage/Image Collage.md>): تركيب صور بتخطيط غير منتظم.
- [Image Auto Orient](<Tools/IMG/Image Auto Orient/Image Auto Orient.md>): تصحيح اتجاه EXIF فقط.
- [Image Color Palette](<Tools/IMG/Image Color Palette/Image Color Palette.md>): استخراج لوحة الألوان السائدة.
- [Image Format Report](<Tools/IMG/Image Format Report/Image Format Report.md>): إحصاءات جماعية لصيغ وأحجام الصور.
- [Video Merge](<Tools/VID/Video Merge/Video Merge.md>): دمج مقاطع الفيديو بالترتيب.
- [Video Screenshot at Time](<Tools/VID/Video Screenshot at Time/Video Screenshot at Time.md>): استخراج لقطة عند ثانية محددة.
- [Video Watermark](<Tools/VID/Video Watermark/Video Watermark.md>): إضافة شعار إلى الفيديو.
- [Video Subtitles Burn](<Tools/VID/Video Subtitles Burn/Video Subtitles Burn.md>): حرق الترجمة داخل الصورة.
- [Video Extract Subtitles](<Tools/VID/Video Extract Subtitles/Video Extract Subtitles.md>): استخراج مسارات الترجمة الأصلية.
- [Video Add Subtitle Track](<Tools/VID/Video Add Subtitle Track/Video Add Subtitle Track.md>): إضافة ترجمة قابلة للإيقاف.
- [Video Remove Black Bars](<Tools/VID/Video Remove Black Bars/Video Remove Black Bars.md>): معاينة اقتراح إزالة الحواف السوداء.
- [Video Audio Sync](<Tools/VID/Video Audio Sync/Video Audio Sync.md>): تقديم أو تأخير الصوت.
