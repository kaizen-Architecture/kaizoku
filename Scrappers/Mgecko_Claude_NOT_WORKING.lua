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
Headless = require("headless")

Client = Http.client()
Browser = Headless.browser()
Base = "https://www.mgeko.cc"
Delay = 3

----- SEARCH MANGA -----
function SearchManga(query)
    -- Usar headless para manejar el formulario de búsqueda
    local page = Browser:page()
    page:navigate(Base .. "/search/")
    page:waitLoad()
    Time.sleep(2)
    
    -- Intentar llenar el formulario y enviarlo
    local success = pcall(function()
        page:element("input[name='inputContent']"):send_keys(query)
        Time.sleep(1)
        page:element("form"):submit()
        page:waitLoad()
        Time.sleep(Delay)
    end)
    
    local html = page:html()
    local doc = Html.parse(html)
    local mangas = {}
    
    -- Buscar items de manga con múltiples selectores
    local selectors = {
        "li.novel-item a",
        "div.novel-item a",
        ".item-title a",
        "a[href*='/manga/']"
    }
    
    for _, selector in ipairs(selectors) do
        doc:find(selector):each(function(i, link)
            local href = link:attr("href")
            if href and href:match("/manga/") then
                local text = trim(link:text())
                if text ~= "" and not mangas_contains(mangas, href) then
                    if not href:match("^http") then
                        href = Base .. href
                    end
                    table.insert(mangas, {
                        name = text,
                        url = href
                    })
                end
            end
        end)
        
        -- Si encontramos resultados, no seguir buscando
        if #mangas > 0 then
            break
        end
    end

    return mangas
end

----- GET CHAPTERS -----
function MangaChapters(mangaURL)
    local request = Http.request("GET", mangaURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)
    local chapters = {}

    doc:find("a[href*='/reader/']"):each(function(i, link)
        local href = link:attr("href")
        if href then
            local text = trim(link:text())
            if text ~= "" then
                if not href:match("^http") then
                    href = Base .. href
                end
                table.insert(chapters, {
                    name = text,
                    url = href
                })
            end
        end
    end)

    Reverse(chapters)
    return chapters
end

----- GET PAGES -----
function ChapterPages(chapterURL)
    local request = Http.request("GET", chapterURL)
    local result = Client:do_request(request)
    local doc = Html.parse(result.body)
    local pages = {}

    doc:find("img[src*='cdn']"):each(function(i, img)
        local src = img:attr("src") or img:attr("data-src")
        if src then
            src = src:gsub("[\n\r\t%s]", "")
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