#!/bin/sh
# Uji alur relay ujung ke ujung: buat live → baca → belum berubah → kirim ulang → token salah → hapus.
# Lokal: `npm run dev` di terminal lain, lalu `npm run smoke`. Hasil deploy: `BASE=https://… npm run smoke`.
set -eu
BASE=${BASE:-http://127.0.0.1:8790}
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
expect() { [ "$1" = "$2" ] && echo "ok   $3" || { echo "GAGAL $3: $1 (harus $2)"; exit 1; }; }

created=$(curl -s -X POST "$BASE/live" -d '{"schema":2,"appVersion":"2.5.0","tournament":{"id":"t1"}}')
live=$(echo "$created" | sed -n 's/.*"code":"\([^"]*\)".*/\1/p')
token=$(echo "$created" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
[ -n "$live" ] && [ -n "$token" ] && echo "ok   POST /live → $live" || { echo "GAGAL POST: $created"; exit 1; }

expect "$(code "$BASE/live/$live")" 200 "GET baru"
expect "$(code "$BASE/live/$live?since=1")" 204 "GET belum berubah"
expect "$(code -X PUT -H "Authorization: Bearer $token" "$BASE/live/$live" -d '{"schema":2,"tournament":{"id":"t1"}}')" 204 "PUT"
curl -s "$BASE/live/$live?since=1" | grep -q '"rev":2' && echo "ok   GET rev 2" || { echo "GAGAL rev 2"; exit 1; }
expect "$(code -X PUT -H 'Authorization: Bearer salah' "$BASE/live/$live" -d '{"schema":2,"tournament":{}}')" 403 "PUT token salah"
expect "$(code -X PUT -H "Authorization: Bearer $token" "$BASE/live/$live" -d 'bukan json')" 400 "PUT bukan turnamen"
expect "$(code -X POST "$BASE/live" -d '{"tournament":{}}')" 400 "POST tanpa schema"
expect "$(code -X OPTIONS "$BASE/live/$live")" 204 "preflight CORS"
expect "$(code -X DELETE -H "Authorization: Bearer $token" "$BASE/live/$live")" 204 "DELETE"
expect "$(code "$BASE/live/$live")" 404 "GET setelah dihapus"
expect "$(code "$BASE/live/abc")" 404 "kode tidak sah"
