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

local xml = require('luaxml-mod-xml')
local handler = require('luaxml-mod-handler')
local dom = require('luaxml-domobject')


local load_xml =  function(url)
  local command = io.popen("wget -qO- ".. url,"r")

  local info = command:read("*all")
  command:close()

  if string.len(info) == 0 then
    return false
  end
  --print(pkginfo)
  treehandler = handler.simpleTreeHandler()
  treehandler.options.noReduce = {authorref=true}
  x = xml.xmlParser(treehandler)
  x:parse(info)
  return treehandler.root
end

local get_authors = function(a)
  local authors = {}
  local retrieved_authors = {}
  -- fix LuaXML "feature" 
  if #a == 0 then a = {a} end
  for _, author in ipairs(a) do
    local current = {}
    current[#current+1] = author._attr.familyname
    current[#current+1] = author._attr.givenname
    table.insert(retrieved_authors, table.concat(current, ", "))
  end
  return table.concat(retrieved_authors," and ")
end

local get_title = function(title)

  local title = title:gsub("^(.)", function(a) return unicode.utf8.upper(a) end)
  return string.format(titleformat, title)
end


local get_url = function(home)
  local home = home or {}
  local attr = home["_attr"] or {}
  local href = attr.href or "http://www.ctan.org/pkg/"..pkgname
  return href
end

local get_version = function(version)
  local version = version or {}
  local attr = version["_attr"] or {}
  return attr["number"], attr["date"]
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

local entry = load_xml(url)

if not entry then
  print("Cannot find entry for package "..pkgname)
  os.exit(1)
end

-- root element is also saved, so we use this trick 
local record = entry.entry

local e = {}

e.author = get_authors(record.authorref)
e.package = pkgname
e.title = get_title(record.name)
e.subtitle = record.caption
e.url = get_url(record.home)
e.version, e.date = get_version(record.version)
e.urldate = os.date("%Y-%m-%d")

local result = compile(bibtexformat, e)

print(result)
