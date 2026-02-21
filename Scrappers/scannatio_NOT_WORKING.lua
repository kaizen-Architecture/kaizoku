--------------------------------------
-- @name    Comick.io
-- @url     https://comick.io/
-- @author  ChatGPT
-- @license MIT
--------------------------------------

Html = require("html")
Http = require("http")
HttpUtil = require("http_util")
Time = require("time")

Client = Http.client()
Base = "https://comick.io"

----- SEARCH MANGA -----
function SearchManga(query)
    query = query:gsub("'", "")
    local url = Base .. "/search?q=" .. HttpUtil.query_escape(query)
    local request = Http.request("GET", url)
    local result = Client:do_request(request)

    if not result or not result.body then
        print("Error: No se pudo obtener resultados de Comick.io")
        return {}
    end

    local doc = Html.parse(result.body)
    local mangas = {}

    local list = doc:find(".comic-list .comic-item")
    if list then
        list:each(function(i, item)
            local a = item:find("a"):first()
            local title = item:find(".comic-title"):first()
            if a and title then
                mangas[i+1] = {
                    name = trim(title:text()),
                    url = Base .. a:attr("href")
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

    if not result or not result.body then
        print("Error: No se pudo obtener capítulos")
        return {}
    end

    local doc = Html.parse(result.body)
    local chapters = {}

    local list = doc:find(".chapter-list li")
    if list then
        list:each(function(i, item)
            local a = item:find("a"):first()
            if a then
                chapters[i+1] = {
                    name = trim(a:text()),
                    url = Base .. a:attr("href")
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

    if not result or not result.body then
        print("Error: No se pudo obtener páginas del capítulo")
        return {}
    end

    local doc = Html.parse(result.body)
    local pages = {}

    doc:find(".page-img img"):each(function(i, img)
        local src = img:attr("data-src") or img:attr("src")
        if src then
            pages[i+1] = {
                index = i+1,
                url = src:gsub("[\n\r\t]", "")
            }
        end
    end)

    return pages
end
