-- @name BatoTo
-- @url https://bato.to
-- @author Kilo Code
-- @license MIT
-- @incompatible: Site uses advanced anti-bot measures that block headless browsers. Search results are JS-rendered and not accessible via current headless implementation in Mangal. HTTP requests return empty results for search. Site may require full browser session or have changed its structure.

----- IMPORTS -----
Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Headless = require("headless")
Time = require("time")
--- END IMPORTS ---

----- VARIABLES -----
Base = "https://bato.to"
Delay = 3
--- END VARIABLES ---

----- LOCAL FUNCTIONS -----
local function Reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end
--- END LOCAL FUNCTIONS ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    local url = Base .. "/search?word=" .. HttpUtil.query_escape(query)
    -- Use headless browser for JS-rendered search results
    local browser = Headless.browser()
    local page = browser:page()
    page:set_user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    page:navigate(url)
    Time.sleep(5)  -- Increased delay for JS loading
    page:waitLoad()
    local doc = Html.parse(page:html())

    local mangas = {}
    doc:find(".col.item.line-b a.item-title"):each(function(i, s)
        local href = s:attr("href")
        if href and not href:find("http") then href = Base .. href end
        local name = s:text():gsub("^%s*(.-)%s*$", "%1")
        if name and name ~= "" and not mangas[name] then
            mangas[#mangas+1] = { name = name, url = href }
            mangas[name] = true  -- to avoid duplicates
        end
    end)

    return mangas
end

--- Gets the list of all manga chapters.
-- @param mangaURL URL of the manga
-- @return Table of tables with the following fields: name, url
function MangaChapters(mangaURL)
    -- Use Headless browser for dynamic content
    local browser = Headless.browser()
    local page = browser:page()
    page:navigate(mangaURL)
    Time.sleep(Delay)
    page:waitLoad()

    local doc = Html.parse(page:html())

    local chapters = {}
    doc:find("a[href*='ch_']"):each(function(i, s)
        local href = s:attr("href")
        if href and not href:find("http") then href = Base .. href end
        local name = s:text()
        if name:find("Chapter") then
            chapters[i+1] = { name = name:gsub("^%s*(.-)%s*$", "%1"), url = href }
        end
    end)

    Reverse(chapters)
    return chapters
end

--- Gets the list of all pages of a chapter.
-- @param chapterURL URL of the chapter
-- @return Table of tables with the following fields: url, index
function ChapterPages(chapterURL)
    -- Use Headless browser for dynamic content
    local browser = Headless.browser()
    local page = browser:page()
    page:navigate(chapterURL)
    Time.sleep(Delay)
    page:waitLoad()

    local doc = Html.parse(page:html())

    local pages = {}
    doc:find(".page-img"):each(function(i, s)
        local src = s:attr("src")
        if src and src ~= "" then
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