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

function hex2num(str)
  local n = 0
  local zero = string.byte("0", 1)
  local a = string.byte("a", 1)
  local A = string.byte("A", 1)
  for i = 1, #str do
    local x = string.byte(str, i)
    if 0 <= x - zero and x - zero <= 9 then
      n = n * 16 + (x - zero)
    elseif 0 <= x - a and x - a < 6 then
      n = n * 16 + 10 + (x - a)
    elseif 0 <= x - A and x - A < 6 then
      n = n * 16 + 10 + (x - A)
    else
      error("Wrong format hexnumber: " .. str)
    end
  end
  return n
end

-- escape

escape_table = {
  ["\x00"] = "\\0",
  ["\x7f"] = "\\x7f",
  ["\x07"] = "\\a",
  ["\x08"] = "\\b",
  ["\x1b"] = "\\e",
  ["\x0c"] = "\\f",
  ["\x0a"] = "\\n",
  ["\x0d"] = "\\r",
  ["\x09"] = "\\t",
  ["\x0b"] = "\\v",
  ["\\"] = "\\\\",
  ["'"] = "\\'",
  ["\""] = "\\\"",
}
function escape_q(str)
  local buf = ""
  for i = 1, #str do
    local b = string.byte(str, i)
    local c = string.sub(str, i, i)
    local e = escape_table[c]
    if e then
      buf = buf .. e
    else
      buf = buf .. c
    end
  end
  return buf
end

unescape_table = {
  ["0"] = "\x00",
  ["a"] = "\x07",
  ["b"] = "\x08",
  ["e"] = "\x1b",
  ["f"] = "\x0c",
  ["n"] = "\x0a",
  ["r"] = "\x0d",
  ["t"] = "\x09",
  ["v"] = "\x0b",
}
function unescape_q(str)
  local buf = ""
  local i = 1
  while i <= #str do
    local c = string.sub(str, i, i)
    if c == "\\" then
      i = i + 1
      local b = string.byte(str, i)
      local c = string.sub(str, i, i)
      local t = unescape_table[c]
      if t then
        buf = buf .. t
      elseif c == "x" then
        i = i + 1
        local h = string.sub(str, i, i + 1)
        local d = hex2num(h)
        buf = buf .. string.char(d)
        i = i + 1
      else
        buf = buf .. c
      end
    else
      buf = buf .. c
    end
    i = i + 1
  end
  return buf
end

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
  local is_absolute = (path[1] == "")
  local parent_level = 0
  local p = {}
  local k = 1
  for _i, v in ipairs(path) do
    if v == ".." then
      if #p == 0 then
        if is_absolute then
          error("Wrong Path: " .. path_tostring(path))
        end
        parent_level = parent_level + 1
      else
        table.remove(p)
      end
    elseif v ~= "" and v ~= "." then
      table.insert(p, v)
    end
  end
  if is_absolute then
    table.insert(p, 1, "")
  else
    for i = 1, parent_level do
      table.insert(p, 1, "..")
    end
  end
  return p
end

function path_parse(str)
  return path_opt(path_split(str))
end

function path_tostring(path)
  local s = ""
  for i, v in ipairs(path) do
    if i > 1 then
      s = s .. "/"
    end
    s = s .. v
  end
  return s
end

function path_cd(base, rel)
  local res = {}
  if rel[1] ~= "" then
    for _i, v in ipairs(base) do
      table.insert(res, v)
    end
  end
  for _i, v in ipairs(rel) do
    table.insert(res, v)
  end
  return path_opt(res)
end

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

-- Source
function Source(filename, content)
  if content == nil then
    content = read_from(filename)
    if content == nil then
      error("Failed to read '" .. escape_q(filename) .."'")
    end
  end
  return {
    filename = filename,
    raw = content,
    content = content, }
end

function Location(src, line, col, p)
  return {
    source = src,
    line = line,
    col = col,
    pos = p, }
end

function ParseState(source)
  return {
    source = source,
    pos = 1,
    line = 1,
    col = 1,
    saved = {}}
end

function refine_source(source)
  -- TODO: remove comments, optimize white characters
end

function PS_pass(ps, n)
  if n == nil then n = 1 end
  for i = 1, n do
    local c = string.sub(ps.raw, ps.pos, ps.pos)
    if c == "\n" then
      ps.line = ps.line + 1
      ps.col = 1
    else
      ps.col = ps.col + 1
    end
    ps.pos = ps.pos + 1
  end
end

-- TODO: WRITE PS HELPERS

-- TODO: WRITE PARSER

---- GEN

---- ENTRY
function entry()
  print("TESTING IZE")
end

------
entry()
