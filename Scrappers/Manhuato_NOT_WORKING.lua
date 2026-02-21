--------------------------------------
-- name ManhuaTo
-- url https://manhuato.com
-- author tuUsuario
-- license MIT
--------------------------------------

Html   = require("html")
Http   = require("http")
Client = Http.client()
Base   = "https://manhuato.com"

local function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local function Reverse(t)
    local n, i = #t, 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i, n = i + 1, n - 1
    end
end

local function slugify(s)
    return s:lower()
            :gsub("[^a-z0-9]+","-")
            :gsub("^-*","")
            :gsub("-*$","")
end

function SearchManga(query)
    local slug = slugify(query)
    -- normalize query into tokens
    local norm = query:lower():gsub("[^a-z0-9 ]+"," ")
    local tokens = {}
    for w in norm:gmatch("%w+") do tokens[#tokens+1] = w end

    local resp = Client:do_request(Http.request("GET", Base.."/search?s="..query))
    local doc  = Html.parse(resp.body)
    local map  = {}

    doc:find("a"):each(function(_, a)
        local href = a:attr("href") or ""
        local name = trim(a:text() or "")
        if name ~= "" then
            local namel = name:lower()
            local hl    = href:lower()
            if not hl:match("/genre/") then
                local ok_slug = hl:match("/"..slug)
                local ok_tokens = true
                for _,t in ipairs(tokens) do
                    if not namel:match(t) then ok_tokens = false break end
                end
                if ok_slug or ok_tokens then
                    if not map[href] then
                        map[href] = {
                            name = name,
                            url  = href:match("^http") and href or Base..href
                        }
                    end
                end
            end
        end
    end)

    local out = {}
    for _,v in pairs(map) do table.insert(out, v) end
    return out
end

function MangaChapters(mangaURL)
    local resp = Client:do_request(Http.request("GET", mangaURL))
    local doc  = Html.parse(resp.body)
    local chapters = {}

    local container = doc:find(".chapter-list, .chapters"):first()
    if container then
        container:find("a"):each(function(_, a)
            local href = a:attr("href") or ""
            if href:match("%-chapter%-") then
                local name = trim(a:text() or "")
                if name ~= "" then
                    chapters[#chapters+1] = {
                        name = name,
                        url  = href:match("^http") and href or Base..href
                    }
                end
            end
        end)
    end

    if #chapters == 0 then
        doc:find("a"):each(function(_, a)
            local href = a:attr("href") or ""
            if href:match("%-chapter%-") then
                local name = trim(a:text() or "")
                if name ~= "" then
                    chapters[#chapters+1] = {
                        name = name,
                        url  = href:match("^http") and href or Base..href
                    }
                end
            end
        end)
    end

    Reverse(chapters)
    return chapters
end

function ChapterPages(chapterURL)
    local resp = Client:do_request(Http.request("GET", chapterURL))
    local doc  = Html.parse(resp.body)
    local pages = {}

    doc:find("img"):each(function(_, img)
        local src = img:attr("src") or img:attr("data-src") or ""
        if src:match("^https?://") then
            pages[#pages+1] = {
                index = #pages+1,
                url   = src
            }
        end
    end)

    return pages
end
