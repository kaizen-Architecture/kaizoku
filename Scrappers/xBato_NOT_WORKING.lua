--------------------------------------
-- @name    XBato
-- @url     https://xbato.com/
-- @author  claude
-- @license MIT
--------------------------------------

----- IMPORTS -----
Html = require("html")
Time = require("time")
Http = require("http")
HttpUtil = require("http_util")
Headless = require("headless")
--- END IMPORTS ---

----- VARIABLES -----
Client = Http.client()
Browser = Headless.browser()
Base = "https://xbato.com"
Delay = 3
--- END VARIABLES ---

----- MAIN -----

function SearchManga(query)
    query = query:gsub("'", "")
    local url = Base .. "/v3x-search?word=" .. HttpUtil.query_escape(query)

    local page = Browser:page()
    page:navigate(url)
    page:waitLoad()
    Time.sleep(Delay)

    local html = page:html()
    local doc = Html.parse(html)
    local mangas = {}

    -- Buscar items de manga
    doc:find("a[href*='/title/']"):each(function(i, link)
        local href = link:attr("href")
        if href and href:match("/title/%d") then
            if not href:match("^http") then
                href = Base .. href
            end
            local name = trim(link:text())
            if name ~= "" and not mangas_contains(mangas, href) then
                table.insert(mangas, {
                    name = name,
                    url = href
                })
            end
        end
    end)

    return mangas
end

function MangaChapters(mangaURL)
    local page = Browser:page()
    page:navigate(mangaURL)
    page:waitLoad()
    Time.sleep(Delay)
    
    local html = page:html()
    local doc = Html.parse(html)
    local chapters = {}

    -- Buscar capítulos con clase chapt
    doc:find("a.chapt"):each(function(i, link)
        local href = link:attr("href")
        if href then
            if not href:match("^http") then
                href = Base .. href
            end
            -- Extraer el texto del <b> que contiene el nombre
            local nameTag = link:find("b"):first()
            local name = ""
            if nameTag then
                name = trim(nameTag:text())
            else
                name = trim(link:text())
            end
            if name ~= "" then
                table.insert(chapters, {
                    name = name,
                    url = href
                })
            end
        end
    end)

    Reverse(chapters)
    return chapters
end

function ChapterPages(chapterURL)
    local page = Browser:page()
    page:navigate(chapterURL)
    page:waitLoad()
    Time.sleep(Delay)

    local doc = Html.parse(page:html())
    local pages = {}

    -- Buscar imágenes del capítulo
    doc:find("img"):each(function(i, img)
        local src = img:attr("src") or img:attr("data-src")
        if src and (src:match("cdn") or src:match("xbato") or src:match("bato")) then
            if src:sub(1,2) == "//" then
                src = "https:" .. src
            elseif not src:match("^http") then
                src = Base .. src
            end
            table.insert(pages, {
                index = #pages + 1,
                url = src
            })
        end
    end)

    return pages
end

--- END MAIN ---

----- HELPERS -----

function trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function Reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end

function mangas_contains(mangas, url)
    for _, manga in ipairs(mangas) do
        if manga.url == url then
            return true
        end
    end
    return false
end

--- END HELPERS ---