# PICT гаралтын мөр бүрт хэдэн [ERROR] утга байгааг тоолно (~ тэмдгийг үл тооно).
# Ажиллуулах: awk -f count-errors.awk results/transfer.txt
BEGIN { FS = "\t" }
NR == 1 { next }
{
  gsub(/\r/, "")
  for (i = 1; i <= NF; i++) { v[i] = $i; sub(/^~/, "", v[i]) }
  e = 0
  if (v[1] != "Valid") e++
  if (v[2] != "Valid") e++
  if (v[3] != "Normal" && v[3] != "EqualBalance") e++
  if (v[5] == "Exhausted") e++
  cnt[e]++; rows++
  # Боломжгүй/хоёрдмол утгатай хослол: OverLimit+Unused (үлдэгдэлд багтах ч лимитээс их байх боломжгүй),
  # EqualBalance+Partial (1 000 000 > лимитийн үлдэгдэл 500 000 -> үнэндээ LIMIT алдаа)
  if ((v[3] == "OverLimit" && v[5] != "Partial") || (v[3] == "EqualBalance" && v[5] != "Unused")) bad++
}
END {
  printf "rows=%d happy(0 error)=%d 1-error=%d 2-error=%d 3-error=%d 4-error=%d max=", rows, cnt[0], cnt[1], cnt[2], cnt[3], cnt[4]
  m = 0; for (k = 0; k <= 4; k++) if (cnt[k] > 0) m = k; printf "%d impossible-or-ambiguous=%d\n", m, bad + 0
}
