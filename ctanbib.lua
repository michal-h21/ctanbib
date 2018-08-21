#!/usr/bin/env texlua
kpse.set_program_name("luatex")
-- ctanbib.lua -- export ctan entries to bib format
--

if #arg < 1 or arg[1]=="--help" or arg[1]=="-h" then 
  print [[ctanbib - convert ctan package information to bibtex format
  Usage:
  texlua ctanbib <package name>

  This command will bibtex entry to the terminal output
  ]]
  os.exit(1)
end

local pkgname = arg[1]
local url = "https://www.ctan.org/xml/pkg/" .. pkgname

-- change that for different title scheme
local titleformat = "The %s package"

local bibtexformat = [[
@manual{$package,
title = {$title},
subtitle = {$subtitle},
author = {$author},
url = {$url},
urldate = {$urldate}, 
date = {$date},
version = {$version}
}
]]

local dom = require('luaxml-domobject')


local load_xml =  function(url)
  local command = io.popen("wget -qO- ".. url,"r")

  local info = command:read("*all")
  command:close()

  if string.len(info) == 0 then
    return false
  end
  return dom.parse(info)
end

local get_authors = function(a)
  local retrieved_authors = {}
  for _, author in ipairs(a) do
    local current = {}
    current[#current+1] = author:get_attribute("familyname")
    current[#current+1] = author:get_attribute("givenname")
    table.insert(retrieved_authors, table.concat(current, ", "))
  end
  return table.concat(retrieved_authors," and ")
end

local get_title = function(record)
  local title = record:query_selector("name")[1]
  if title then
    title = title:get_text()
    title = title:gsub("^(.)", function(a) return unicode.utf8.upper(a) end)
  else
    title = pkgname
  end
  return string.format(titleformat, title)
end


local get_url = function(record)
  local home = record:query_selector("home")[1]
  if home then return home:get_attribute("href") end
  return "http://www.ctan.org/pkg/"..pkgname
end

local get_caption = function(record)
  local caption = record:query_selector("caption")[1]
  if caption then return caption:get_text() end
  return nil
end

local get_version = function(record)
  local version = record:query_selector("version")[1]
  if version then
    return version:get_attribute("number"), version:get_attribute("date")
  end
end

local bibtex_escape = function(a)
  local a = a or ""
  return a:gsub("([%$%{%}])", function(x) return '\\'..x end)
end

local compile = function(template, records)
  return template:gsub("$([a-z]+)", function(a) 
    return bibtex_escape(records[a]) or ""
  end)
end

local record = load_xml(url)

if not record then
  print("Cannot find entry for package "..pkgname)
  os.exit(1)
end

-- root element is also saved, so we use this trick 
-- local record = entry.entry

local e = {}

e.author = get_authors(record:query_selector("authorref"))
e.package = pkgname
e.title = get_title(record)
e.subtitle = get_caption(record)
e.url = get_url(record)
e.version, e.date = get_version(record)
e.urldate = os.date("%Y-%m-%d")

local result = compile(bibtexformat, e)

print(result)
