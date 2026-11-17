# Grammar lessons. Exercise shorthand:
#   ("mc", prompt, promptAr, [options], answer, explanationAr)
#   ("fill", prompt, promptAr, "answer|alternative", explanationAr)
#   ("order", promptAr, "correct sentence", explanationAr)

LESSONS = [
{
 "id": "a1-to-be", "level": "A1", "title": "The verb 'to be'", "titleAr": "فعل الكينونة: am / is / are",
 "summaryAr": "في العربية نقول «أنا طالب» بدون فعل، لكن الإنجليزية تحتاج دائماً فعل be.",
 "sections": [
  ("التصريف", "نستخدم am مع I، وis مع he/she/it، وare مع you/we/they.", ["I am a student.", "She is a doctor.", "They are at home."]),
  ("النفي والسؤال", "للنفي نضيف not بعد الفعل. وللسؤال نقدّم الفعل على الفاعل.", ["He is not (isn't) busy.", "Are you ready?", "Is it cold today?"]),
 ],
 "tip": "لا تحذف الفعل! الخطأ الشائع: «She very happy» والصحيح: She is very happy.",
 "ex": [
  ("mc", "She ___ my sister.", "اختر الكلمة الصحيحة", ["am", "is", "are"], "is", "مع she نستخدم is."),
  ("mc", "We ___ from Jordan.", "اختر الكلمة الصحيحة", ["is", "am", "are"], "are", "مع we نستخدم are."),
  ("fill", "I ___ a teacher.", "أكمل الفراغ", "am|'m", "مع I نستخدم am دائماً."),
  ("fill", "___ they at school? (question)", "أكمل السؤال", "are", "للسؤال نبدأ بالفعل: Are they…?"),
  ("order", "رتّب الكلمات لتكوين جملة صحيحة", "My father is an engineer", "الترتيب: الفاعل + is + الوصف. ولاحظ an قبل engineer لأنها تبدأ بصوت متحرك."),
  ("mc", "Which sentence is correct?", "أي جملة صحيحة؟", ["He happy.", "He is happy.", "He are happy."], "He is happy.", "لا يمكن حذف is في الإنجليزية."),
 ]
},
{
 "id": "a1-present-simple", "level": "A1", "title": "Present simple", "titleAr": "المضارع البسيط",
 "summaryAr": "للعادات والحقائق والأشياء التي تتكرّر.",
 "sections": [
  ("القاعدة", "نستخدم الفعل كما هو، ونضيف s أو es مع he/she/it.", ["I drink tea every day.", "She works in a hospital.", "Water boils at 100 degrees."]),
  ("النفي والسؤال", "نستخدم do/does. ومع does يعود الفعل لأصله بدون s.", ["He doesn't like coffee.", "Do you speak English?", "Does she live here?"]),
 ],
 "tip": "لا تنسَ s مع he/she/it: «He go» خطأ، والصحيح He goes.",
 "ex": [
  ("mc", "My brother ___ football every Friday.", "اختر الصحيح", ["play", "plays", "playing"], "plays", "مع my brother (he) نضيف s."),
  ("mc", "___ you like pizza?", "اختر الصحيح", ["Does", "Do", "Are"], "Do", "مع you نستخدم Do."),
  ("fill", "She ___ (not / like) spicy food.", "اكتب الصيغة المنفية", "doesn't like|does not like", "مع she: doesn't + الفعل بدون s."),
  ("fill", "He ___ (watch) TV in the evening.", "صرّف الفعل", "watches", "الأفعال المنتهية بـ ch نضيف لها es."),
  ("order", "رتّب الكلمات", "Where do you live", "السؤال: كلمة الاستفهام + do + الفاعل + الفعل."),
 ]
},
{
 "id": "a1-articles", "level": "A1", "title": "Articles: a, an, the", "titleAr": "أدوات التعريف والتنكير",
 "summaryAr": "من أصعب النقاط على العرب: متى نستخدم a/an، ومتى the، ومتى لا شيء.",
 "sections": [
  ("a / an", "مع الاسم المفرد المعدود عند ذكره لأول مرة أو لوصف المهنة. an قبل الصوت المتحرك.", ["I have a car.", "She is an engineer.", "It takes an hour."]),
  ("the", "عندما يكون الشيء معروفاً أو مذكوراً سابقاً أو فريداً.", ["I bought a book. The book is great.", "The sun is hot.", "Close the door, please."]),
  ("بدون أداة", "مع الجمع والأشياء غير المعدودة عند التعميم.", ["I like cats.", "Money isn't everything.", "Children love games."]),
 ],
 "tip": "في العربية نقول «الحياة جميلة» مع «ال»، لكن بالإنجليزية: Life is beautiful (بدون the) لأننا نتكلم بشكل عام.",
 "ex": [
  ("mc", "He is ___ honest man.", "اختر الأداة", ["a", "an", "the"], "an", "honest تبدأ بصوت متحرك لأن h صامتة."),
  ("mc", "I love ___ music.", "اختر الأداة", ["the", "a", "— (no article)"], "— (no article)", "عند الحديث عن الموسيقى بشكل عام لا نستخدم أداة."),
  ("mc", "Can you open ___ window?", "اختر الأداة", ["a", "the", "an"], "the", "نافذة معروفة للطرفين."),
  ("fill", "My sister is ___ doctor.", "أكمل بالأداة", "a", "مع المهن نستخدم a/an."),
  ("fill", "___ moon is beautiful tonight.", "أكمل بالأداة", "the", "القمر شيء فريد فنستخدم the."),
 ]
},
{
 "id": "a2-past-simple", "level": "A2", "title": "Past simple", "titleAr": "الماضي البسيط",
 "summaryAr": "لأحداث انتهت في وقت محدّد في الماضي.",
 "sections": [
  ("الأفعال المنتظمة والشاذة", "نضيف ed للأفعال المنتظمة، والشاذة لها صيغ خاصة يجب حفظها.", ["I visited my grandmother yesterday.", "We went to the beach last summer.", "She bought a new dress."]),
  ("النفي والسؤال", "نستخدم did، ويعود الفعل لأصله.", ["I didn't see him.", "Did you finish your work?", "Where did they go?"]),
 ],
 "tip": "بعد did يأتي الفعل في أصله: «Did you went» خطأ، والصحيح Did you go.",
 "ex": [
  ("mc", "We ___ a great film last night.", "اختر الصحيح", ["see", "saw", "seen"], "saw", "see فعل شاذ وماضيه saw."),
  ("mc", "Did she ___ the email?", "اختر الصحيح", ["sent", "send", "sends"], "send", "بعد did الفعل بدون تصريف."),
  ("fill", "They ___ (travel) to Turkey in 2022.", "صرّف الفعل", "travelled|traveled", "فعل منتظم: travel → travelled."),
  ("fill", "I ___ (not / go) to work yesterday.", "اكتب النفي", "didn't go|did not go", "النفي: didn't + الفعل الأصلي."),
  ("order", "رتّب الكلمات", "What time did you wake up", "السؤال بالماضي: كلمة الاستفهام + did + الفاعل + الفعل."),
 ]
},
{
 "id": "a2-continuous", "level": "A2", "title": "Present continuous vs present simple", "titleAr": "المضارع المستمر مقابل البسيط",
 "summaryAr": "المستمر لما يحدث الآن أو مؤقتاً، والبسيط للعادات والحقائق.",
 "sections": [
  ("المضارع المستمر", "am/is/are + فعل ing لشيء يحدث الآن أو هذه الفترة أو خطة قريبة.", ["I'm reading a great book these days.", "Look! It's raining.", "We're meeting Ali tomorrow."]),
  ("أفعال الحالة", "أفعال مثل know, like, want, need لا تأتي عادة بصيغة ing.", ["I know the answer.", "She wants a coffee.", "Do you understand?"]),
 ],
 "tip": "خطأ شائع: «I am knowing him» والصحيح I know him.",
 "ex": [
  ("mc", "Be quiet! The baby ___.", "اختر الصحيح", ["sleeps", "is sleeping", "sleep"], "is sleeping", "شيء يحدث الآن."),
  ("mc", "I usually ___ to work by bus.", "اختر الصحيح", ["am going", "go", "goes"], "go", "usually تدل على عادة."),
  ("mc", "I ___ what you mean.", "اختر الصحيح", ["am understanding", "understand", "understanding"], "understand", "understand فعل حالة."),
  ("fill", "What ___ you ___ now? (do)", "أكمل بالكلمتين مفصولتين بمسافة", "are doing", "السؤال بالمستمر: are + you + doing."),
  ("order", "رتّب الكلمات", "She is studying for her exams this week", "this week فترة مؤقتة → مستمر."),
 ]
},
{
 "id": "a2-comparatives", "level": "A2", "title": "Comparatives and superlatives", "titleAr": "المقارنة والتفضيل",
 "summaryAr": "للمقارنة بين شيئين أو اختيار الأفضل بين مجموعة.",
 "sections": [
  ("المقارنة", "صفة قصيرة + er + than، أو more + صفة طويلة + than.", ["Amman is bigger than Irbid.", "This book is more interesting than that one.", "My car is older than yours."]),
  ("التفضيل", "the + صفة + est، أو the most + صفة طويلة. وهناك صيغ شاذة: good-better-best.", ["It's the tallest building in the city.", "She is the most intelligent student.", "This is the best day of my life."]),
 ],
 "tip": "لا تجمع بين الطريقتين: «more bigger» خطأ، والصحيح bigger.",
 "ex": [
  ("mc", "Today is ___ than yesterday.", "اختر الصحيح", ["hotter", "more hot", "hottest"], "hotter", "hot صفة قصيرة: hotter."),
  ("mc", "This is the ___ restaurant in town.", "اختر الصحيح", ["better", "best", "good"], "best", "التفضيل من good هو the best."),
  ("fill", "English is ___ (easy) than Chinese.", "أكمل", "easier", "easy → easier (y تتحول إلى i)."),
  ("fill", "It was the ___ (expensive) hotel we stayed in.", "أكمل", "most expensive", "صفة طويلة: the most expensive."),
  ("order", "رتّب الكلمات", "My brother is taller than me", "صيغة المقارنة + than."),
 ]
},
{
 "id": "b1-present-perfect", "level": "B1", "title": "Present perfect vs past simple", "titleAr": "المضارع التام مقابل الماضي البسيط",
 "summaryAr": "لا يوجد زمن مقابل له في العربية، لذا يحتاج تركيزاً خاصاً.",
 "sections": [
  ("المضارع التام", "have/has + التصريف الثالث: لتجربة حياة بدون وقت محدد، أو شيء بدأ ومستمر، أو نتيجة تهمّنا الآن.", ["I have visited London twice.", "She has lived here since 2015.", "I've lost my keys!"]),
  ("الماضي البسيط", "عندما نذكر وقتاً محدداً انتهى.", ["I visited London in 2019.", "She moved here five years ago.", "I lost my keys yesterday."]),
  ("since و for", "since مع نقطة البداية، وfor مع المدة.", ["since Monday / since 2010", "for three hours / for ten years"]),
 ],
 "tip": "لا نستخدم المضارع التام مع وقت ماضٍ محدد: «I have seen him yesterday» خطأ، والصحيح I saw him yesterday.",
 "ex": [
  ("mc", "I ___ this film three times.", "اختر الصحيح", ["saw", "have seen", "see"], "have seen", "تجربة بدون وقت محدد."),
  ("mc", "We ___ to Paris last year.", "اختر الصحيح", ["have gone", "went", "have been"], "went", "last year وقت محدد → ماضٍ بسيط."),
  ("mc", "He has worked here ___ 2018.", "اختر الصحيح", ["for", "since", "from"], "since", "2018 نقطة بداية → since."),
  ("fill", "___ you ever ___ sushi? (eat)", "أكمل بكلمتين مفصولتين بمسافة", "have eaten", "Have you ever + التصريف الثالث."),
  ("fill", "She has been a teacher ___ ten years.", "أكمل", "for", "ten years مدة → for."),
  ("order", "رتّب الكلمات", "I have never been to Japan", "never تأتي بين have والتصريف الثالث."),
 ]
},
{
 "id": "b1-future", "level": "B1", "title": "Future: will vs going to", "titleAr": "المستقبل: will أو going to",
 "summaryAr": "كلاهما للمستقبل لكن بمعانٍ مختلفة.",
 "sections": [
  ("will", "لقرار لحظي، أو وعد، أو توقّع مبني على رأي.", ["I'll help you with that.", "I think it will rain tomorrow.", "I promise I'll call you."]),
  ("going to", "لخطة مقرّرة مسبقاً، أو توقّع مبني على دليل نراه.", ["We're going to buy a house next year.", "Look at those clouds! It's going to rain."]),
 ],
 "tip": "بعد will يأتي الفعل الأصلي بدون to: «I will to go» خطأ.",
 "ex": [
  ("mc", "The phone is ringing. — I ___ answer it.", "اختر الصحيح", ["am going to", "will", "going"], "will", "قرار لحظي."),
  ("mc", "I've already decided. I ___ study medicine.", "اختر الصحيح", ["will", "am going to", "going to"], "am going to", "خطة مقرّرة مسبقاً."),
  ("mc", "Be careful! You ___ fall!", "اختر الصحيح", ["will", "are going to", "go to"], "are going to", "توقّع مبني على دليل أمامنا."),
  ("fill", "Don't worry, I ___ tell anyone. (promise, negative)", "أكمل", "won't|will not", "الوعد بالنفي: won't."),
  ("order", "رتّب الكلمات", "What are you going to do this weekend", "سؤال عن خطة: be going to."),
 ]
},
{
 "id": "b1-conditionals", "level": "B1", "title": "First and second conditional", "titleAr": "الجمل الشرطية الأولى والثانية",
 "summaryAr": "الأولى لاحتمال حقيقي في المستقبل، والثانية لموقف خيالي أو غير مرجّح.",
 "sections": [
  ("الشرطية الأولى", "If + مضارع بسيط، will + فعل.", ["If it rains, we'll stay at home.", "If you study, you'll pass."]),
  ("الشرطية الثانية", "If + ماضٍ بسيط، would + فعل.", ["If I had more money, I would travel the world.", "If I were you, I would accept the offer."]),
 ],
 "tip": "لا نستخدم will بعد if: «If it will rain» خطأ، والصحيح If it rains.",
 "ex": [
  ("mc", "If you heat ice, it ___.", "اختر الصحيح", ["melts", "would melt", "melted"], "melts", "حقيقة علمية."),
  ("mc", "If I ___ rich, I would buy an island.", "اختر الصحيح", ["am", "were", "will be"], "were", "شرطية ثانية: If I were."),
  ("fill", "If she calls, I ___ (tell) her the news.", "أكمل", "will tell|'ll tell", "شرطية أولى: will + فعل."),
  ("fill", "What ___ you do if you lost your phone?", "أكمل", "would", "شرطية ثانية: would."),
  ("order", "رتّب الكلمات", "If I were you I would talk to him", "If I were you للنصيحة."),
 ]
},
{
 "id": "b2-passive", "level": "B2", "title": "The passive voice", "titleAr": "المبني للمجهول",
 "summaryAr": "عندما يكون الفعل أهمّ من الفاعل، أو الفاعل غير معروف.",
 "sections": [
  ("التكوين", "be (بالزمن المناسب) + التصريف الثالث.", ["English is spoken all over the world.", "The bridge was built in 1990.", "The results will be announced tomorrow."]),
  ("ذكر الفاعل", "نذكر الفاعل بـ by عند الحاجة فقط.", ["The novel was written by Naguib Mahfouz.", "My car has been stolen!"]),
 ],
 "tip": "لا تنسَ فعل be: «The house built in 1980» خطأ، والصحيح The house was built in 1980.",
 "ex": [
  ("mc", "This museum ___ every year by millions of people.", "اختر الصحيح", ["visits", "is visited", "visited"], "is visited", "مبني للمجهول في المضارع."),
  ("mc", "The letters ___ yesterday.", "اختر الصحيح", ["were sent", "sent", "are sent"], "were sent", "yesterday → ماضٍ: were sent."),
  ("fill", "The new hospital ___ (open) next month.", "اكتب صيغة المستقبل المجهول", "will be opened", "will be + التصريف الثالث."),
  ("fill", "My phone has ___ (repair).", "أكمل", "been repaired", "has been + التصريف الثالث."),
  ("order", "رتّب الكلمات", "The meeting was cancelled because of the storm", "مبني للمجهول بالماضي."),
 ]
},
{
 "id": "b2-reported-speech", "level": "B2", "title": "Reported speech", "titleAr": "الكلام المنقول",
 "summaryAr": "لنقل ما قاله شخص آخر، غالباً بإرجاع الزمن خطوة للخلف.",
 "sections": [
  ("إرجاع الزمن", "المضارع → ماضٍ، الماضي → ماضٍ تام، will → would.", ["\"I'm tired.\" → She said (that) she was tired.", "\"I will help.\" → He said he would help."]),
  ("الأسئلة المنقولة", "نستخدم ترتيب الجملة الخبرية، ومع أسئلة yes/no نستخدم if أو whether.", ["She asked me where I lived.", "He asked if I was ready."]),
 ],
 "tip": "في السؤال المنقول لا نقلب الترتيب: «She asked where did I live» خطأ.",
 "ex": [
  ("mc", "\"I love this city.\" → He said he ___ the city.", "اختر الصحيح", ["loves", "loved", "has loved"], "loved", "المضارع يصبح ماضياً."),
  ("mc", "She asked me ___.", "اختر الصحيح", ["where do I work", "where I worked", "where did I work"], "where I worked", "ترتيب خبري في السؤال المنقول."),
  ("fill", "\"I will call you.\" → He promised he ___ call me.", "أكمل", "would", "will → would."),
  ("fill", "\"Are you hungry?\" → She asked ___ I was hungry.", "أكمل", "if|whether", "سؤال yes/no → if/whether."),
  ("order", "رتّب الكلمات", "He told me that he had finished the report", "الماضي يصبح ماضياً تاماً."),
 ]
},
{
 "id": "b2-relative", "level": "B2", "title": "Relative clauses", "titleAr": "الجمل الموصولة",
 "summaryAr": "لربط المعلومات باستخدام who, which, that, whose, where.",
 "sections": [
  ("أسماء الموصول", "who للأشخاص، which للأشياء، that للاثنين، whose للملكية، where للمكان.", ["The man who called you is my uncle.", "The book which I bought is excellent.", "That's the woman whose son is a pilot.", "This is the café where we met."]),
  ("لا ضمير إضافي", "لا نكرّر الضمير بعد اسم الموصول كما نفعل بالعربية.", ["The car that I bought is red. (not: that I bought it)"]),
 ],
 "tip": "بالعربية نقول «السيارة التي اشتريتها»، لكن بالإنجليزية لا نضيف it: The car that I bought.",
 "ex": [
  ("mc", "The student ___ won the prize is from Egypt.", "اختر الصحيح", ["which", "who", "whose"], "who", "شخص → who."),
  ("mc", "I know a girl ___ father is a famous singer.", "اختر الصحيح", ["who", "whose", "which"], "whose", "ملكية → whose."),
  ("mc", "Which sentence is correct?", "أي جملة صحيحة؟", ["The phone that I bought it is broken.", "The phone that I bought is broken."], "The phone that I bought is broken.", "لا نكرّر الضمير it."),
  ("fill", "That's the hotel ___ we stayed last summer.", "أكمل", "where", "مكان → where."),
  ("order", "رتّب الكلمات", "The film which we watched was amazing", "which للأشياء."),
 ]
},
{
 "id": "c1-inversion", "level": "C1", "title": "Inversion for emphasis", "titleAr": "القلب للتوكيد",
 "summaryAr": "أسلوب رسمي قوي يُستخدم في الكتابة والخطابة وامتحان IELTS.",
 "sections": [
  ("بعد التعابير السلبية", "عند بدء الجملة بـ Never, Rarely, Not only, Hardly نقلب الفاعل والفعل المساعد.", ["Never have I seen such a beautiful view.", "Not only did she win, but she also broke the record.", "Rarely do we get such an opportunity."]),
  ("Only / No sooner", "Only after, Only when, No sooner… than.", ["Only after the meeting did I understand the problem.", "No sooner had we arrived than it started to rain."]),
 ],
 "tip": "استخدم القلب باعتدال؛ فهو رسمي وقد يبدو غريباً في الحديث اليومي.",
 "ex": [
  ("mc", "Never ___ such a delicious meal.", "اختر الصحيح", ["I have eaten", "have I eaten", "I ate"], "have I eaten", "بعد Never نقلب: have I."),
  ("mc", "Not only ___ late, but he also forgot the tickets.", "اختر الصحيح", ["he was", "was he", "he is"], "was he", "Not only + قلب."),
  ("fill", "Rarely ___ he complain about anything. (present)", "أكمل بالفعل المساعد", "does", "Rarely + does + فاعل + فعل."),
  ("fill", "No sooner had I sat down ___ the phone rang.", "أكمل", "than", "No sooner… than."),
  ("order", "رتّب الكلمات", "Only then did I realise my mistake", "Only then + did + فاعل + فعل."),
 ]
},
{
 "id": "c1-mixed-conditionals", "level": "C1", "title": "Third and mixed conditionals", "titleAr": "الشرطية الثالثة والمختلطة",
 "summaryAr": "للحديث عن الماضي الذي لم يحدث ونتائجه.",
 "sections": [
  ("الشرطية الثالثة", "If + ماضٍ تام، would have + التصريف الثالث (ماضٍ لم يحدث).", ["If I had studied harder, I would have passed.", "If we had left earlier, we wouldn't have missed the train."]),
  ("المختلطة", "شرط في الماضي ونتيجة في الحاضر، أو العكس.", ["If I had taken that job, I would be rich now.", "If she weren't so shy, she would have spoken at the meeting."]),
 ],
 "tip": "خطأ شائع: «If I would have known» والصحيح If I had known.",
 "ex": [
  ("mc", "If they ___ the map, they wouldn't have got lost.", "اختر الصحيح", ["checked", "had checked", "would check"], "had checked", "شرطية ثالثة: had + التصريف الثالث."),
  ("mc", "If I had saved money, I ___ a car now.", "اختر الصحيح", ["would have", "would have had", "had"], "would have", "شرط ماضٍ ونتيجة حاضرة: would have (يمتلك الآن)."),
  ("fill", "If you had told me, I ___ helped you.", "أكمل بكلمتين مفصولتين بمسافة", "would have", "would have + التصريف الثالث."),
  ("order", "رتّب الكلمات", "If I had known I would have come", "شرطية ثالثة كاملة."),
 ]
},
]
