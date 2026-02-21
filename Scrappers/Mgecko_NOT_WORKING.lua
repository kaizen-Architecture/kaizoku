--------------------------------------
-- @name    Mgeko
-- @url     https://www.mgeko.cc/
-- @author  mpiva
-- @license MIT
--------------------------------------

Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Time = require("time")

Client = Http.client()
Base = "https://www.mgeko.cc"
Delay = 2

----- SEARCH MANGA -----
function SearchManga(query)
    -- Step 1: GET the main page to fetch CSRF token
    local getRequest = Http.request("GET", Base .. "/search/")
    local getResult = Client:do_request(getRequest)
    local doc = Html.parse(getResult.body)
    local csrfInput = doc:find("input[name='csrfmiddlewaretoken']"):first()
    local token = csrfInput and csrfInput:attr("value") or ""

    -- Step 2: POST the search
    local postRequest = Http.request("POST", Base .. "/search/")
    postRequest:form_set("csrfmiddlewaretoken", token)
    postRequest:form_set("inputContent", query)
    postRequest:header_set("Content-Type", "application/x-www-form-urlencoded")
    local result = Client:do_request(postRequest)
    local doc = Html.parse(result.body)
    local mangas = {}

    local list = doc:find("ul.novel-list.grid.col.col2"):first()
    if list then
        list:find("li.novel-item"):each(function(i, item)
            local link = item:find("a"):first()
            local title = item:find("h4.novel-title"):first()
            if link and title then
                mangas[i+1] = {
                    name = trim(title:text()),
                    url = Base .. link:attr("href")
                }
            end
        end)
    end

    return mangas
end

----- GET CHAPTERS -----
function MangaChapters(mangaURL)
    local request = Http.request("GET", mangaURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)
    local chapters = {}

    local list = doc:find("ul.chapter-list li.chapter-list-item"):first() or doc:find("section#chapters"):first()
    if list then
        doc:find("ul.chapter-list li.chapter-list-item"):each(function(i, s)
            local link = s:find("a"):first()
            if link then
                chapters[i+1] = {
                    name = trim(link:text()),
                    url = Base .. link:attr("href")
                }
            end
        end)
    end

    Reverse(chapters)
    return chapters
end

----- GET PAGES -----
function ChapterPages(chapterURL)
    local request = Http.request("GET", chapterURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)
    local pages = {}

    doc:find("#viewer > div > img"):each(function(i, img)
        local src = img:attr("src")
        if src then
            pages[i+1] = { index = i+1, url = src:gsub("[\n\r\t]", "") }
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
