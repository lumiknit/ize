#!/bin/sh
_=[[
IFS=:
for D in ${PATH}; do
  for F in "${D}"/lua "${D}"/lua5* "${D}"/luajit*; do
    if [ -x "${F}"  ]; then
      exec "${F}" "$0" "$@"
    fi
  done
done
printf "%s: no Lua interpreter found\n" "${0##*/}" >&2
exit 1
]]

-- ize.lua 0.0.1d
-- lumiknit (aasr4r4@gmail.com)
print("Interpreter Version: " .. _VERSION)

---- PARSE

---- GEN

---- ENTRY

function main()
  print("MAIN")
end

main()
