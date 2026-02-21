--------------------------------------
-- @name TopManhua
-- @url https://www.topmanhua.fan
-- @author Kilo Code
-- @license MIT
--------------------------------------

----- IMPORTS -----
Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Headless = require("headless")
Time = require("time")
--- END IMPORTS ---

----- VARIABLES -----
Client = Http.client()
Browser = Headless.browser()
Base = "https://www.topmanhua.fan"
Delay = 1
--- END VARIABLES ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    local url = Base .. "/?s=" .. HttpUtil.query_escape(query) .. "&post_type=wp-manga"
    local request = Http.request("GET", url)
    request:set_header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    request:set_header("Accept-Language", "en-US,en;q=0.9")
    request:set_header("Referer", Base)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local mangas = {}
    doc:find(".row.c-tabs-item__content"):each(function(i, r)
        local titleElement = r:find("h3.h4 a"):first()
        if titleElement then
            local href = titleElement:attr("href")
            if href and not href:find("http") then href = Base .. href end
            mangas[i+1] = { name = titleElement:text():gsub("^%s*(.-)%s*$", "%1"), url = href }
        end
    end)

    return mangas
end

--- Gets the list of all manga chapters.
-- @param mangaURL URL of the manga
-- @return Table of tables with the following fields: name, url
function MangaChapters(mangaURL)
    -- Use headless for dynamic content
    local page = Browser:page()
    page:navigate(mangaURL)
    Time.sleep(Delay)
    page:waitLoad()
    local doc = Html.parse(page:html())

    local chapters = {}
    doc:find(".wp-manga-chapter a"):each(function(i, s)
        local href = s:attr("href")
        if href and not href:find("http") then href = Base .. href end
        chapters[i+1] = { name = s:text():gsub("^%s*(.-)%s*$", "%1"), url = href }
    end)

    Reverse(chapters)
    return chapters
end

--- Gets the list of all pages of a chapter.
-- @param chapterURL URL of the chapter
-- @return Table of tables with the following fields: url, index
function ChapterPages(chapterURL)
    -- Use Headless browser for dynamic content
    local page = Browser:page()
    page:navigate(chapterURL)
    Time.sleep(Delay)
    page:waitLoad()

    local doc = Html.parse(page:html())

    local pages = {}
    doc:find("img.wp-manga-chapter-img"):each(function(i, s)
        local src = s:attr("src") or s:attr("data-src")
        if src and not src:find("loading") then
            src = src:gsub("^%s*(.-)%s*$", "%1")
            if not src:find("http") then
                if src:sub(1,2) == "//" then src = "https:" .. src
                elseif src:sub(1,1) == "/" then src = Base .. src
                else src = Base .. "/" .. src end
            end
            pages[i+1] = { index = i+1, url = src }
        end
    end)

    return pages
end

--- END MAIN ---

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
--- END HELPERS ---