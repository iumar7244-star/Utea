# جسر الوصول لحل مشكلة الرسوب

A responsive revision, memorisation and quiz website for **التاريخ الإسلامي** (Islamic History).

## What changed in v3

- **Renamed** from "IUS AND SONS" to **جسر الوصول لحل مشكلة الرسوب** everywhere (title, header, footer, meta tags).
- **Term selection added.** Home page now walks the student through: **Term → Topic → Mode**.
  - الفصل الأول (First Term): 06 الخلفاء الراشدون (24), 07 قيام الدولة الأموية (5)
  - الفصل الثاني (Second Term): no topics yet — shown as "coming soon" (edit `TERMS` in `questions.js` once you have them)
  - الفصل الثالث (Third Term): 01 الدولة الأموية في الأندلس (8), 02 عبد الرحمن الداخل (11), 03 عبد الرحمن الأوسط (9), 04 عبد الرحمن الناصر (17), 05 انهيار الدولة في الأندلس (9)
  - All topics belong to one subject: **التاريخ الإسلامي**.
- **Full paper mode.** Selecting a topic + a study mode now shows *every* question in that topic on one scrollable "paper" — no more one-question-at-a-time. Answer everything, tap **تصحيح الورقة / Mark paper**, and see every question marked in place plus a full score summary. Works across all three modes (choice, typing, revision).
- **Boot / splash video.**
  - Portrait video (`intro-portrait.mp4`) plays on phones/tablets held in portrait.
  - Landscape video (`intro-landscape.mp4`) plays on desktop or phones/tablets held in landscape.
  - Detected automatically via screen orientation; plays once per browser session; has a skip button; falls back safely if autoplay is blocked.
- Arabic/English switch for the **website interface only**; quiz content stays in Arabic.
- Local progress tracking with localStorage (unchanged).

## Files

- `index.html` – markup
- `style.css` – styling
- `app.js` – all logic (term/topic/mode wizard, full-paper quiz engine, i18n, boot splash)
- `questions.js` – the question bank (`QUESTIONS`) plus new `TOPIC_META` and `TERMS` metadata
- `intro-portrait.mp4`, `intro-landscape.mp4` – boot/splash videos (converted from the supplied .mov files to H.264 for broad browser support)

## Editing terms/topics

Open `questions.js` and edit the `TERMS` array at the bottom:

```js
const TERMS = [
  { id: 'first',  ar: 'الفصل الأول',  en: 'First Term',  topics: ['06', '07'] },
  { id: 'second', ar: 'الفصل الثاني', en: 'Second Term', topics: [] },
  { id: 'third',  ar: 'الفصل الثالث', en: 'Third Term',  topics: ['01', '02', '03', '04', '05'] }
];
```

Each entry in `topics` is a topic `code` from `TOPIC_META` (also at the bottom of `questions.js`). To populate Second Term, just move or add codes to its `topics` array.

## Run

Open `index.html` directly, or deploy all files (including the two `.mp4` files) to GitHub Pages. No database or server is required.

## v5 update

- **Second Term is now live**: added "الفترة الثانية" (73 questions — Abbasid–Byzantine wars, the decline of the Abbasid state, Islamic civilization under the Abbasids, and the states that broke from the caliphate) under الفصل الثاني. It was previously an empty placeholder term; it now has real content, no cloud setup required.
- **New: `library.html`** — "مكتبة جسر الوصول لحل مشكلة الرسوب", a public page (linked from the header) listing 6 reference PDFs grouped by educational stage:
  - **الابتدائية**: تحفة الأطفال والغلمان (Tajweed poem), and the author's own Grade 6 Tajweed booklet
  - **الإعدادية**: the author's original History booklet — the actual source the site's Islamic History question bank was built from
  - **الثانوية**: three university-level Arabic Balagha texts (علم البيان / المعاني / البديع) by Dr. Mohammed Kalo
  - All 6 files live in `/library/` and download directly, no login needed.

## v6 update — accounts & platform admin

- **`login.html` rebuilt**: it now shows an actual, obvious **Sign Up** form (Name, Email, Password) and a **Log In** form (Email, Password) as tabs on one page, plus a **"Log in with Google"** button. Signing up creates the account and the school in one step and goes straight to the dashboard.
- The header link used to say "دخول الإدارة" (Admin login), which is why sign-up wasn't obviously visible — it's now "تسجيل الدخول / إنشاء حساب" (Sign Up / Log In).
- **Google sign-in** needs a one-time setup in your Supabase project (Authentication → Providers → Google, with a Google Cloud OAuth Client ID/Secret) — I can't create that Google Cloud project for you from here, but the code is ready and will work once it's enabled.
- **New: platform-wide admin** (`schema-superadmin.sql`, `superadmin.js`, `superadmin.html`). Run the SQL once — it only *adds* new tables/policies, it never touches or removes anything existing. Then:
  1. Sign up on the site with the email you want as admin, password `Assalaamalaikum` (Supabase needs a real email — "Admin" alone can't sign up).
  2. In the Supabase SQL editor, run:
     ```sql
     insert into public.platform_admins (user_id)
     select id from auth.users where email = 'the-email-you-used';
     ```
  3. Log in with that account → you'll see a **"لوحة المنصة"** link in the dashboard, leading to `superadmin.html`: every school, every registered user, and a button to manage (edit/add/delete topics, questions and PDFs) any school's content, plus delete any school outright.
- `cloud-questions.js` and `pdfs.js` now accept an optional school ID, which is how the platform admin can edit content that belongs to a different school than their own — enforced by the new database policies, not just the UI.
