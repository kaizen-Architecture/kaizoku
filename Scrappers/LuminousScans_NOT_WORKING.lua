--------------------------------------
-- name Mangaread
-- url https://www.mangaread.org
-- author improved_scraper
-- license MIT
--------------------------------------

Html = require("html")
Http = require("http")

Base = "https://www.mangaread.org"
Client = Http.client()

-- DOCUMENTATION:
-- Mangaread.org structure analysis:
-- Search: Uses GET parameter ?s=query (NOT /search/query)
-- Results: Container .page-listing-item contains manga cards
-- Manga page: URL format /manga/slug/
-- Chapters: Listed in .listing-chapters_wrap > .wp-manga-chapter links
-- Pages: Images in .reading-content img with data-src attribute
-- Verified with: One Punch Man, Overgeared, Eleceed
-- Note: Site uses static HTML, no JavaScript required for basic content

function trims(str)
    if not str then return "" end
    return str:gsub("^%s*(.-)%s*$", "%1")
end

function Reverse(array)
    local n = #array
    for i = 1, math.floor(n / 2) do
        array[i], array[n - i + 1] = array[n - i + 1], array[i]
    end
    return array
end

function urlencode(str)
    if str then
        str = str:gsub("\n", "\r\n")
        str = str:gsub("([^%w _%%%-%.~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = str:gsub(" ", "+")
    end
    return str
end

-- Extract domain from URL for relative link resolution
function resolve_url(link, base_url)
    if link:find("^https?://") then
        return link
    elseif link:find("^//") then
        return "https:" .. link
    elseif link:find("^/") then
        local domain = base_url:match("^(https?://[^/]+)")
        return domain .. link
    else
        return base_url .. "/" .. link
    end
end

-- Search manga by title
function SearchManga(query)
    local results = {}
    local encoded = urlencode(query)
    local url = Base .. "/?s=" .. encoded
    
    local res, err = Client:get(url)
    if not res then
        return results
    end
    
    local html = Html.parse(res)
    if not html then
        return results
    end
    
    -- Container for manga cards in search results
    local items = html:select(".page-listing-item")
    
    for i = 1, #items do
        local item = items[i]
        
        -- Extract manga link and title
        local link_elem = item:select(".manga-item-title a"):first()
        if not link_elem then
            link_elem = item:select("a"):first()
        end
        
        if link_elem then
            local name = trims(link_elem:text())
            local link = link_elem:attr("href")
            
            if name and name ~= "" and link and link ~= "" then
                link = resolve_url(link, Base)
                
                -- Try to extract author
                local author = ""
                local author_elem = item:select(".author-content"):first()
                if author_elem then
                    author = trims(author_elem:text())
                end
                
                -- Try to extract genres
                local genres = ""
                local genre_elem = item:select(".manga-item-genres"):first()
                if genre_elem then
                    genres = trims(genre_elem:text())
                end
                
                local entry = {
                    name = name,
                    url = link
                }
                
                if author ~= "" then
                    entry.author = author
                end
                
                if genres ~= "" then
                    entry.genres = genres
                end
                
                table.insert(results, entry)
            end
        end
    end
    
    return results
end

-- Get all chapters for a manga
function MangaChapters(mangaURL)
    local chapters = {}
    
    local res, err = Client:get(mangaURL)
    if not res then
        return chapters
    end
    
    local html = Html.parse(res)
    if not html then
        return chapters
    end
    
    -- Chapters container - usually in reverse order (newest first)
    local nodes = html:select(".listing-chapters_wrap .wp-manga-chapter a")
    
    if #nodes == 0 then
        -- Alternative selector if first one fails
        nodes = html:select(".wp-manga-chapter a")
    end
    
    for i = 1, #nodes do
        local a = nodes[i]
        local name = trims(a:text())
        local link = a:attr("href")
        
        if name and name ~= "" and link and link ~= "" then
            link = resolve_url(link, Base)
            
            table.insert(chapters, {
                name = name,
                url = link
            })
        end
    end
    
    -- Reverse to get oldest chapter first
    return Reverse(chapters)
end

-- Get all page images from a chapter
function ChapterPages(chapterURL)
    local pages = {}
    
    local res, err = Client:get(chapterURL)
    if not res then
        return pages
    end
    
    local html = Html.parse(res)
    if not html then
        return pages
    end
    
    -- Main reading content container
    local imgs = html:select(".reading-content img")
    
    if #imgs == 0 then
        -- Alternative selector
        imgs = html:select(".page-break img")
    end
    
    for i = 1, #imgs do
        local img = imgs[i]
        
        -- Try data-src first (lazy loading), then src
        local src = img:attr("data-src") or img:attr("data-lazy-src") or img:attr("src")
        
        if src and src ~= "" then
            src = resolve_url(src, chapterURL)
            
            table.insert(pages, {
                index = i,
                url = src
            })
        end
    end
    
    return pages
end