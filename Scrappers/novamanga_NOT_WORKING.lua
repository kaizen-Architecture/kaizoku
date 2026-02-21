--------------------------------------
-- @name NovaManga
-- @url https://novamanga.com
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
Base = "https://novamanga.com"
Delay = 1
--- END VARIABLES ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    -- Use headless browser for search since results are JS-rendered
    local url = Base .. "/search?search=" .. HttpUtil.query_escape(query)
    local page = Browser:page()
    page:navigate(url)
    Time.sleep(Delay)
    page:waitLoad()
    local doc = Html.parse(page:html())

    local mangas = {}
    -- Primary selector for search results - look for manga cards
    doc:find("a[href*='/series/']"):each(function(i, r)
        local titleElement = r:find("p"):first()
        if titleElement then
            local href = r:attr("href")
            if href and not href:find("http") then href = Base .. href end
            local name = titleElement:text():gsub("^%s*(.-)%s*$", "%1")
            -- Filter out non-manga results and duplicates
            if name ~= "" and not name:find("Chapter") and not name:find("chapter") and not name:find("Episode") then
                -- Check if already exists to avoid duplicates
                local exists = false
                for _, existing in ipairs(mangas) do
                    if existing.name == name then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(mangas, { name = name, url = href })
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
    -- Use headless browser for dynamic chapter loading
    local page = Browser:page()
    page:navigate(mangaURL)
    Time.sleep(Delay)
    page:waitLoad()
    local doc = Html.parse(page:html())

    local chapters = {}
    doc:find("[data-episodes] a.recentCardItem"):each(function(i, s)
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
    local request = Http.request("GET", chapterURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local pages = {}
    doc:find("img"):each(function(i, s)
        local src = s:attr("data-src") or s:attr("src")
        if src and not src:find("loading") and not src:find("logo") and not src:find("icon") then
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