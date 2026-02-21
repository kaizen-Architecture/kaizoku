--------------------------------------
-- @name    Mangahub
-- @url     https://mangahub.io
-- @author  AI Assistant
-- @license MIT
--------------------------------------

Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Strings = require("strings")
Headless = require("headless")
Time = require("time")

Client = Http.client()
Browser = Headless.browser()
Base = "https://mangahub.io"
Delay = 1

function SearchManga(query)
    local url = Base .. "/search?q=" .. HttpUtil.query_escape(query)
    local request = Http.request("GET", url)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local mangas = {}
    doc:find("h4.media-heading a"):each(function(i, s)
        local text = s:text()
        if text and text ~= "" then
            text = Strings.trim(text)
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

function MangaChapters(mangaURL)
    local request = Http.request("GET", mangaURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local chapters = {}
    doc:find("#chapters .chapter-link"):each(function(i, s)
        local text = s:text()
        if text and text ~= "" then
            text = Strings.trim(text)
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

function ChapterPages(chapterURL)
    local request = Http.request("GET", chapterURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)

    local pages = {}
    doc:find("#reader img"):each(function(i, s)
        local src = s:attr("src")
        if src then
            if not src:find("http") then
                if src:sub(1,2) == "//" then src = "https:" .. src
                elseif src:sub(1,1) == "/" then src = Base .. src
                else src = Base .. "/" .. src end
            end
            table.insert(pages, { index = #pages + 1, url = src })
        end
    end)

    return pages
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