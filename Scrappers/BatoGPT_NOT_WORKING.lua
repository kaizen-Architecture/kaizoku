--------------------------------------
-- @name    Bato.to
-- @url     https://bato.to/
-- @author  mpiva
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
Base = "https://bato.to"
Delay = 3 -- seconds
--- END VARIABLES ---

----- MAIN -----

--- Searches for manga with given query.
-- @param query Query to search for
-- @return Table of tables with the following fields: name, url
function SearchManga(query)
    query = query:gsub("'", "")
    local url = Base .. "/search?word=" .. HttpUtil.query_escape(query)

    local page = Browser:page()
    page:navigate(url)
    page:waitLoad()
    Time.sleep(Delay)

    local html = page:html()
    local doc = Html.parse(html)
    local mangas = {}

    local seriesList = doc:find("#series-list"):first()

    if seriesList then
        seriesList:find(".col.item"):each(function(i, item)
            local titleLink = item:find(".item-title"):first()
            if titleLink then
                local href = titleLink:attr("href")
                if not href:match("^http") then
                    href = Base .. href
                end
                table.insert(mangas, {
                    name = trim(titleLink:text()),
                    url = href
                })
            end
        end)
    end

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

    -- Bato.to cambia bastante el DOM, probamos varios contenedores
    local containers = {
        ".chapter-list",
        "#chapters",
        ".episodes",
        ".main"
    }

    for _, selector in ipairs(containers) do
        local chapterContainer = doc:find(selector):first()
        if chapterContainer then
            chapterContainer:find("a[href*='/chapter/']"):each(function(i, link)
                local href = link:attr("href")
                if not href:match("^http") then
                    href = Base .. href
                end
                local name = trim(link:text())
                if name ~= "" then
                    table.insert(chapters, {
                        name = name,
                        url = href
                    })
                end
            end)
        end
    end

    Reverse(chapters)
    return chapters
end

--- Gets the list of all pages of a chapter.
-- @param chapterURL URL of the chapter
-- @return Table of tables with the following fields: url, index
function ChapterPages(chapterURL)
    local page = Browser:page()
    page:navigate(chapterURL)
    page:waitLoad()
    Time.sleep(Delay)

    local doc = Html.parse(page:html())
    local pages = {}

    doc:find("#viewer img, .viewer img"):each(function(i, img)
        local src = img:attr("src") or img:attr("data-src")
        if src then
            if src:sub(1,2) == "//" then
                src = "https:" .. src
            elseif not src:match("^http") then
                src = Base .. src
            end
            table.insert(pages, {
                index = #pages + 1,
                url = src:gsub("[\n\r\t]", "")
            })
        end
    end)

    return pages
end

----- HELPERS -----

function trim(s)
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
