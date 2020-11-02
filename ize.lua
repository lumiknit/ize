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

---- Util

-- pp
function ps(src, depth)
  local ty = type(src)
  if depth == nil then
    depth = 0
  end
  if ty == "table" then
    if depth < 4 then
      local b = ""
      local is_first = true
      for k, v in pairs(src) do
        if is_first then
          is_first = false
        else
          b = b .. ", "
        end
        b = b .. ps(k, depth + 1)
        b = b .. ": "
        b = b .. ps(v, depth + 1)
      end
      return "{" .. b .. "}"
    else
      return "{...}"
    end
  elseif ty == "string" then
    return "\"" .. src .. "\""
  else
    return tostring(src)
  end
end

function pp(src)
  print(ps(src, 0))
end

-- flatten items
function flatten(src)
  local b = ""
  local is_first_chunk = true
  for _k, v in ipairs(src) do
    local ty = type(v)
    if ty == "table" then
      b = b .. flatten(v)
    elseif ty == "string" then
      b = b .. v
    else
      b = b .. tostring(v)
    end
  end
  return b
end

-- file io
function read_from(filename)
  local file = io.open(filename, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content
  end
end

function write_to(filename, content)
  local file = io.open(filename, "w")
  if file then
    file:write(content)
    file:close()
  end
end

-- path helper
function path_split(path)
  local t = {}
  local p = 1
  local l = #path
  while p <= l do
    local q = string.find(path, "/", p)
    if q == nil then
      table.insert(t, string.sub(path, p))
      break
    else
      table.insert(t, string.sub(path, p, q - 1))
      p = q + 1
    end
  end
  return t
end

function path_opt(path)
  local p = {}
  local k = 1
  local l = #path
  if k -- EDITING
end

function path_cd(base, rel)
end

pp(path_parent(path_split("aade")))

---- Lua Gen
-- The below construct flattable string

function lg_sep(items, sep)
  local t = {}
  for i, v in ipairs(items) do
    if i > 1 then
      table.insert(t, sep)
    end
    table.insert(t, v)
  end
  return t
end

function lg_comment(content)
  return {"-- ", content}
end

function lg_op(lhs, op, rhs)
  return {"(", lhs, " ", op, " ", rhs, ")"}
end

function lg_assign(lhs, rhs, is_local)
  if is_local then
    return {"local ", lhs, " = ", rhs}
  else
    return {lhs, " = ", rhs}
  end
end

function lg_body(items)
  return lg_sep(items, "\n")
end

function lg_comma(items)
  return lg_sep(items, ", ")
end

function lg_args(items_tup)
  return {"(", items_tup, ")"}
end

function lg_table(items_tup)
  return {"{", items_tup, "}"}
end

function lg_function(args, body)
  return {"(function", args, "\n", body, "\nend)"}
end

function lg_call(target, args)
  return {target, args}
end

function lg_if(cond, then_case, else_case)
  return {"if (", cond, ") then\n", then_case,
    "\nelse\n", else_case, "\nend"}
end

function lg_while(cond, body)
  return {"while (", cond, ") do\n", body, "\nend"}
end

---- PARSE

---- GEN

---- ENTRY
function entry()
  print("TESTING IZE")
end

------
entry()
