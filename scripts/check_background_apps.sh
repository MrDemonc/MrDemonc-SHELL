#!/usr/bin/env bash
pgrep -i telegram >/dev/null 2>&1 && tg=true || tg=false
(pgrep -i discord >/dev/null 2>&1 || pgrep -i webcord >/dev/null 2>&1) && dc=true || dc=false
pgrep -i spotify >/dev/null 2>&1 && sp=true || sp=false
pgrep -x steam >/dev/null 2>&1 && stm=true || stm=false

echo "{\"telegram\":$tg,\"discord\":$dc,\"spotify\":$sp,\"steam\":$stm}"
