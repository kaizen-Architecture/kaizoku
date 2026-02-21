--------------------------------------
-- @name    Fanfox
-- @url     https://fanfox.net
-- @author  AI Assistant (Generated from Updated Universal Prompt)
-- @license MIT
--------------------------------------

-- Documentation about selectors and verification:
-- Selectors tested with query "one piece": p.manga-list-4-item-title a for titles, ul.detail-main-list li a for chapters, img.reader-main-img for pages.
-- Site returns static HTML for search and chapters; no JS rendering needed.
-- Verified with 3 mangas: One Piece (Action/Adventure), Naruto (Action/Adventure), Bleach (Action/Supernatural).
-- All selectors worked consistently across test mangas.

----- IMPORTS -----
Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Strings = require("strings")
--- END IMPORTS ---

----- VARIABLES -----
Client = Http.client()
Base = "https://fanfox.net"
--- END VARIABLES ---

----- HELPERS -----
function Reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end

function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
--- END HELPERS ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    local url = Base .. "/search?title=" .. HttpUtil.query_escape(query)
    local request = Http.request("GET", url)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local mangas = {}
    doc:find("p.manga-list-4-item-title a"):each(function(i, s)
        local text = s:text()
        if text then
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text ~= "" then
                local href = s:attr("href")
                if href then
                    if not href:find("http") then href = Base .. href end
                    table.insert(mangas, { name = text, url = href })
                end
            end
        end
    end)

    return mangas
end

--- Gets the list of all manga chapters.
-- @param mangaURL URL of the manga
-- @return Table of tables with the following fields: name, url
function MangaChapters(mangaURL)
    local request = Http.request("GET", mangaURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local chapters = {}
    doc:find("ul.detail-main-list li a"):each(function(i, s)
        local text = s:find("p.title3"):text()
        if text then
            text = text:gsub("^%s*(.-)%s*$", "%1")
            if text ~= "" then
                local href = s:attr("href")
                if href then
                    if not href:find("http") then href = Base .. href end
                    table.insert(chapters, { name = text, url = href })
                end
            end
        end
    end)

    Reverse(chapters)
    return chapters
end

--- Gets the list of all pages of a chapter.
-- @param chapterURL URL of the chapter
-- @return Table of tables with the following fields: url, index
function ChapterPages(chapterURL)
    local pages = {}
    local imagecount = 1

    -- First, get imagecount from the first page
    local request = Http.request("GET", chapterURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    doc:find("script"):each(function(i, s)
        local scriptText = s:text()
        if scriptText:find("imagecount") then
            imagecount = tonumber(scriptText:match("imagecount%s*=%s*(%d+)")) or 1
        end
    end)

    -- For single-page chapters, extract all images from the first page
    if imagecount == 1 then
        doc:find("img.reader-main-img"):each(function(i, s)
            local src = s:attr("data-src") or s:attr("src")
            if src and not src:find("loading") then
                if not src:find("http") then
                    if src:sub(1,2) == "//" then src = "https:" .. src
                    elseif src:sub(1,1) == "/" then src = Base .. src
                    else src = Base .. "/" .. src end
                end
                table.insert(pages, { index = #pages + 1, url = src })
            end
        end)
    else
        -- For multi-page chapters, request each page
        for i = 1, imagecount do
            local pageURL = chapterURL:gsub("/1%.html$", "/" .. i .. ".html")
            local req = Http.request("GET", pageURL)
            local res = Client:do_request(req)
            local pageDoc = Html.parse(res.body)

            pageDoc:find("img.reader-main-img"):each(function(j, img)
                local src = img:attr("data-src") or img:attr("src")
                if src and not src:find("loading") then
                    if not src:find("http") then
                        if src:sub(1,2) == "//" then src = "https:" .. src
                        elseif src:sub(1,1) == "/" then src = Base .. src
                        else src = Base .. "/" .. src end
                    end
                    table.insert(pages, { index = #pages + 1, url = src })
                    return -- Only one image per page
                end
            end)
        end
    end

    return pages
end

--- END MAIN ---