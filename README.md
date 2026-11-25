# Лаборатори №6: Тест тохиолдол боловсруулах — Category-Partition ба PICT

F.CSA313 — 2026

- **Оюутан:** Ө.Манлайбаяр
- **Код:** B222270080

**Орчин:** Windows 11 + Git Bash. PICT-ийг `~/tools/pict`-д (репоос гадна) clone хийж, MinGW-w64 GCC 16.2 (WinLibs)-ээр `make`-ээр эх кодоос бүтээсэн. Windows дээр cmake-ийн бүтээлт `cli/Resource.rc` (UTF-16 кодчилолтой, зөвхөн exe-ийн хувилбарын мэдээлэлтэй) файлыг MinGW-ийн `windres` уншиж чадаагүй тул лабын заасан `make` хувилбарыг ашиглав. Нотолгоо — `results/pict-build.txt`:

```
pict commit ab76c25 2026-09-08
Pairwise Independent Combinatorial Testing

Usage: pict model [options]
```

---

# Хэсэг A: Category-Partition — `POST /transfer`

## Олон алдааны давуу эрэмбэ

Нэг хүсэлтэд хэд хэдэн алдаа зэрэг байвал **from → to → amount** дарааллаар, тус бүрийн дотор **байхгүй → төлөв** (NO_FROM → FROZEN, NO_TO → SAME_ACCOUNT), amount-д **BAD_AMOUNT → INSUFFICIENT → LIMIT** гэж эхний таарсан алдааг буцаана гэж тогтоов: байхгүй дансны царцаасан эсэхийг шалгах боломжгүй, үлдэгдэл/лимитийн шалгалт нь хоёр данс тодорхой болж ханш хөрвүүлсний дараа л утга учиртай, үлдэгдэл хүрэлцэхгүй нь лимитээс илүү "хатуу" (өдөр солигдоход ч засагдахгүй) хязгаар тул түрүүлж шалгана.

Бүрэн эрэмбэ: `NO_FROM > FROZEN > NO_TO > SAME_ACCOUNT > BAD_AMOUNT > INSUFFICIENT > LIMIT`

## A1. Сонголт ба төлөөлөх утгууд (A2-ын хязгаарлалттай)

| Параметр / орчин | Сонголт (category) | Төлөөлөх утга (choice) | Хязгаарлалт |
|---|---|---|---|
| `from` | Дансны оршин байх ба төлөв | **Valid** — байгаа, царцаагдаагүй данс (`A-100`, үлдэгдэл 1 000 000₮) | `[property fromOK]` |
|  |  | **Frozen** — байгаа ч царцаагдсан (`A-200`) | `[ERROR]` |
|  |  | **Missing** — байхгүй ID (`A-999`) | `[ERROR]` |
| `to` | Хүлээн авах данс | **Valid** — байгаа, `from`-оос өөр (`B-300`) | `[property toOK]` |
|  |  | **Missing** — байхгүй ID (`B-999`) | `[ERROR]` |
|  |  | **SameAsFrom** — `to == from` | `[ERROR]` |
| `amount` (хөрвүүлсний дараах дүнгээр) | Тэмдэг ба хэмжээ | **Negative** — `-5000` | `[ERROR]` |
|  |  | **Zero** — `0` | `[ERROR]` |
|  |  | **Normal** — `0 < дүн ≤ min(үлдэгдэл, лимитийн үлдэгдэл)` (`50 000₮`) | `[property amountOK]` |
|  |  | **EqualBalance** — яг үлдэгдэлтэй тэнцүү (`1 000 000₮`, лимит хүрэлцэнэ) | `[SINGLE]` |
|  |  | **OverBalance** — үлдэгдлээс 1 нэгжээр их (`1 000 001₮`) | `[ERROR]` |
|  |  | **OverLimit** — үлдэгдэлд багтана, өдрийн лимитийн үлдэгдлээс их | `[ERROR]` |
| `currency` | Дансны валюттай харьцуулахад | **Same** — `MNT` (данс MNT) | `[property sameCur]` |
|  |  | **Different** — `USD` → ханшаар MNT болгоно | `[property convert]` |
| *Далд орчин:* өдрийн лимит | Өнөөдөр лимит хэр дүүрсэн бэ | **Unused** — өнөөдөр шилжүүлэг хийгээгүй (лимит 5 000 000₮ бүтэн) | — |
|  |  | **Partial** — 4 000 000₮ ашигласан (1 000 000₮ үлдсэн) | — |
|  |  | **Exhausted** — лимит бүрэн дүүрсэн (0₮ үлдсэн) | `[ERROR]` |

Бусад далд орчин: ханшийн утга (тогтмол гэж үзэв), дансны үлдэгдэл (amount-ийн утгууд үлдэгдэлтэй харьцангуй тодорхойлогдсон тул тусад нь category гаргаагүй).

## A2. Хязгаарлалтын үндэслэл

- **`[ERROR]`** — `from`=Frozen/Missing, `to`=Missing/SameAsFrom, `amount`=Negative/Zero/OverBalance/OverLimit, лимит=Exhausted: тус бүр нэг тодорхой ERROR кодыг үүсгэх бөгөөд бусад утгатай хослуулах нь шинэ мэдээлэл өгөхгүй (эхний алдаа бусдаа нууна — error masking), тиймээс тус бүрийг ганц удаа, бусад нь хүчинтэй үед шалгана.
- **`[SINGLE]`** — `amount`=EqualBalance: хилийн (boundary) утга бөгөөд амжилттай болох ёстой ч бүх currency/лимит хослолтой давтах шаардлагагүй тул нэг удаа шалгана.
- **`[property]`/`[IF]`** — Normal/EqualBalance amount нь зөвхөн `[if fromOK and toOK]` үед утга учиртай (үгүй бол үлдэгдлийг тооцох данс байхгүй); `Different` currency `[property convert]` нь amount-ийн утгууд хөрвүүлсний дараах дүнгээр сонгогдохыг шаардана; лимит Partial нь `[if amountOK]` — зөвхөн хэвийн дүнтэй үед лимитийн үлдэгдэл үр дүнд нөлөөлнө.

## Тестийн хүрээний тоо: N → M

- **Бүрэн олонлог (хязгаарлалтгүй):** from 3 × to 3 × amount 6 × currency 2 × лимит 3 = **324**
- **Хязгаарлалтын дараа:**
  - `[ERROR]` утга бүр 1 фрейм: 2 (from) + 2 (to) + 4 (amount) + 1 (лимит) = **9**
  - `[SINGLE]` утга: EqualBalance = **1**
  - Үлдсэн хүчинтэй хослол: from Valid(1) × to Valid(1) × amount Normal(1) × currency (2) × лимит Unused/Partial (2) = **4**
  - Нийт: 9 + 1 + 4 = **14**

**324 → 14**

## A3. Спецификацийн хүснэгт (16 мөр)

Хүснэгтэд үлдэгдэл 1 000 000₮, өдрийн лимит 5 000 000₮, 1 USD = 3 500₮ гэж үзэв.

| # | from | to | amount | currency | лимит | Хүлээгдэх үр дүн | Тайлбар |
|---|---|---|---|---|---|---|---|
| 1 | Valid | Valid | Normal (50 000) | Same | Unused | **201 OK** | Happy path |
| 2 | Valid | Valid | Normal (10 USD = 35 000₮) | Different | Partial | **201 OK** | Хөрвүүлэлттэй happy path |
| 3 | Valid | Valid | EqualBalance (1 000 000) | Same | Unused | **201 OK** | `[SINGLE]` хил — үлдэгдэл 0 болно |
| 4 | Missing | Valid | Normal | Same | Unused | 200 **ERROR_NO_FROM** | |
| 5 | Frozen | Valid | Normal | Same | Unused | 200 **ERROR_FROZEN** | |
| 6 | Valid | Missing | Normal | Same | Unused | 200 **ERROR_NO_TO** | |
| 7 | Valid | SameAsFrom | Normal | Same | Unused | 200 **ERROR_SAME_ACCOUNT** | |
| 8 | Valid | Valid | Zero (0) | Same | Unused | 200 **ERROR_BAD_AMOUNT** | |
| 9 | Valid | Valid | Negative (-5 000) | Same | Unused | 200 **ERROR_BAD_AMOUNT** | |
| 10 | Valid | Valid | OverBalance (1 000 001) | Same | Unused | 200 **ERROR_INSUFFICIENT** | Хилээс +1 |
| 11 | Valid | Valid | OverLimit (900 000 > 1 000 000 − ... лимит үлдэгдэл 500 000) | Same | Partial* | 200 **ERROR_LIMIT** | *4 500 000₮ ашигласан |
| 12 | Valid | Valid | Normal (50 000) | Same | Exhausted | 200 **ERROR_LIMIT** | Далд орчны `[ERROR]` |
| 13 | Valid | Valid | OverBalance (300 USD = 1 050 000₮) | Different | Unused | 200 **ERROR_INSUFFICIENT** | 300 < 1 000 000 боловч хөрвүүлсний дараа хэтэрнэ — хөрвүүлэлтийн дүрмийг шалгана |
| 14 | Frozen | Missing | Normal | Same | Unused | 200 **ERROR_FROZEN** | Давхар нөхцөл: from > to |
| 15 | Valid | Missing | Zero | Same | Unused | 200 **ERROR_NO_TO** | Давхар нөхцөл: to > amount |
| 16 | Valid | Valid | 2 000 000 (үлдэгдэл ба лимит хоёулаа хэтэрсэн) | Same | Partial | 200 **ERROR_INSUFFICIENT** | Давхар нөхцөл: INSUFFICIENT > LIMIT |

Мөр 1–13 нь A2-ын 14 фреймийг (Different+Unused хослолоос бусдыг) хамарч, 14–16 нь давуу эрэмбийг шалгах нэмэлт давхар нөхцөл юм.
