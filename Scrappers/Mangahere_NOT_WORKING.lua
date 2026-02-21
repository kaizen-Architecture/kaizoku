--------------------------------------
-- @name    Mangahere
-- @url     https://www.mangahere.cc
-- @author  AI Assistant (Generated from Universal Prompt)
-- @license MIT
--------------------------------------

----- IMPORTS -----
Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Strings = require("strings")
-- Headless = require("headless")  -- Uncomment if needed for dynamic content
-- Time = require("time")          -- For delays
--- END IMPORTS ---

----- VARIABLES -----
Client = Http.client()
-- Browser = Headless.browser()    -- Uncomment if needed
Base = "https://www.mangahere.cc"
Delay = 1 -- seconds
--- END VARIABLES ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    local url = Base .. "/search?title=&genres=&nogenres=&sort=&stype=1&name=" .. HttpUtil.query_escape(query) .. "&type=0&author_method=cw&author=&artist_method=cw&artist=&rating_method=eq&rating=&released_method=eq&released=&st=0"
    local request = Http.request("GET", url)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local mangas = {}
    doc:find(".manga-list-4-item-title a"):each(function(i, s)
        local text = s:text()
        if text then
            text = Strings.trim(text)
            if text and text ~= "" then
                local href = s:attr("href")
                if href and not href:find("http") then href = Base .. href end
                mangas[i+1] = { name = text, url = href }
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
    -- MangaHere chapters are in .detail-main-list li a or similar; adjust based on HTML
    doc:find(".detail-main-list li a"):each(function(i, s)
        local text = s:text()
        if text and text ~= "" then
            local href = s:attr("href")
            if href and not href:find("http") then href = Base .. href end
            chapters[i+1] = { name = Strings.trim(text), url = href }
        end
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
    doc:find("#image img"):each(function(i, s)
        local src = s:attr("src")
        if src then
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