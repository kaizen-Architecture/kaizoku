--------------------------------------
-- @name    MangaHub
-- @url     https://mangahub.io/
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
Base = "https://mangahub.io"
Delay = 3
--- END VARIABLES ---

----- MAIN -----

function SearchManga(query)
    local url = Base .. "/search?q=" .. HttpUtil.query_escape(query)
    local page = Browser:page()
    page:navigate(url)
    page:waitLoad()
    Time.sleep(Delay)

    local html = page:html()
    local doc = Html.parse(html)
    local mangas = {}

    -- Intentar con media-left que solo tiene el link de la imagen
    doc:find(".media-manga"):each(function(i, item)
        local link = item:find(".media-left a"):first()
        if link then
            local href = link:attr("href")
            if href then
                if not href:match("^http") then
                    href = Base .. href
                end
                -- Extraer el alt de la imagen como nombre
                local img = link:find("img"):first()
                if img then
                    local name = img:attr("alt")
                    if name and name ~= "" then
                        table.insert(mangas, {
                            name = trim(name),
                            url = href
                        })
                    end
                end
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

    -- Buscar enlaces principales (clase _3pfyN)
    doc:find("a._3pfyN"):each(function(i, link)
        local href = link:attr("href")
        if href and href:match("/chapter/") then
            if not href:match("^http") then
                href = Base .. href
            end
            -- Extraer el texto del span _2IG5P
            local nameSpan = link:find("span._2IG5P"):first()
            local name = ""
            if nameSpan then
                name = trim(nameSpan:text())
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

    doc:find("img"):each(function(i, img)
        local src = img:attr("src") or img:attr("data-src")
        if src and (src:match("mghcdn") or src:match("cdn")) then
            if src:sub(1,2) == "//" then
                src = "https:" .. src
            end
            table.insert(pages, {
                index = #pages + 1,
                url = src
            })
        end
    end)

    return pages
end

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