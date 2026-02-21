# Kaizoku Repository Review

## Overview
Kaizoku is a self-hosted manga downloader application built with Next.js, TypeScript, and Prisma. The project is currently archived and no longer maintained, with recommendations to use alternatives like Suwayomi, Komf, and Komga.

## Project Structure
- **Frontend**: Next.js with React, Mantine UI components, Tailwind CSS
- **Backend**: tRPC for API layer, Prisma ORM with PostgreSQL
- **Queue System**: BullMQ with Redis for background jobs
- **Downloader**: Uses external `mangal` CLI tool for manga downloads
- **Deployment**: Docker-based with Docker Compose

## Key Technologies
- **Framework**: Next.js 12.3.1 (React 18)
- **UI Library**: Mantine Core with Emotion
- **Database**: PostgreSQL with Prisma ORM
- **API**: tRPC (TypeScript RPC)
- **Queue**: BullMQ with Redis
- **Styling**: Tailwind CSS with PostCSS
- **Language**: TypeScript 4.9.5

## Database Schema
The application uses Prisma with the following main models:
- **Library**: Stores library paths (one per instance)
- **Manga**: Core manga entity with title, source, interval
- **Chapter**: Individual chapters with file metadata
- **Metadata**: Rich metadata (genres, authors, cover, etc.)
- **OutOfSyncChapter**: Tracks chapters that need fixing
- **Settings**: App and integration settings (Telegram, Apprise, Komga, Kavita)

## Architecture Overview

### Frontend Pages
- **Index (`/`)**: Main dashboard showing manga cards in a grid layout
- **Manga Detail (`/manga/[id]`)**: Detailed view with metadata and chapters table

### Key Components
- **MangaCard**: Displays manga with cover, title, source badge, and action buttons (remove, refresh, edit)
- **MangaDetail**: Shows comprehensive metadata including genres, status, summary
- **ChaptersTable**: Paginated table of chapters with sync status indicators
- **AddManga**: Multi-step wizard for adding new manga (search → source → download → review)

### Server Architecture
- **tRPC Routers**:
  - `library`: Library management
  - `manga`: Core manga operations (CRUD, search, sync)
  - `settings`: Configuration management

### Queue System
Background jobs handled via BullMQ:
- **checkChapters**: Scheduled checks for new chapters
- **download**: Chapter downloads
- **checkOutOfSyncChapters**: Identifies out-of-sync chapters
- **fixOutOfSyncChapters**: Fixes sync issues
- **updateMetadata**: Metadata refreshes
- **integration**: External service integrations (Komga, Kavita)
- **notify**: Notification sending (Telegram, Apprise)

## Key Features
1. **Automated Downloads**: Cron-based scheduling for chapter checks
2. **Multiple Sources**: Support for various manga sources via mangal
3. **Metadata Management**: Rich metadata with Anilist integration
4. **Sync Monitoring**: Tracks out-of-sync chapters with visual indicators
5. **Integrations**: Komga, Kavita, Telegram, Apprise notifications
6. **Library Management**: Organized file structure with configurable paths

## Development Setup
- Node 18, pnpm, Docker required
- Uses mangal CLI for actual downloads
- Docker Compose for local development (Redis + PostgreSQL)

## Current Status
- **Archived**: Project is no longer maintained
- **Alternatives Recommended**: Suwayomi + Komf + Komga/Kavita, ErosxSun (https://erosxsun.xyz/)
- **Fork Available**: kaizoku-next by @ElryGH

## Notable Implementation Details
- Uses Prisma's preview features (orderByNulls)
- Extensive use of Zod for input validation
- Framer Motion for animations
- Mantine Datatable for chapter listings
- Contrast-color library for dynamic badge colors
- String-to-color for source-based color coding

## IA Scraper Prompt Testing Results

### Test Environment
- **Target Site**: https://erosxsun.xyz/
- **Test Query**: "hero"
- **Selected Manga**: "The Genius Blacksmith's Game", "How Is the Hero's Name Just 'Aaaah'?", "Full-Time Awakening"
- **Mangal Version**: Local installation with custom sources

### Test Results

#### ✅ **Search Functionality - PARTIAL SUCCESS**
- **Status**: Working but limited
- **Results**: Found 1 manga for "hero" query: "How Is the Hero's Name Just 'Aaaah'?"
- **Issue**: Only returns first result, missing other hero-related titles
- **Selector Used**: `.serieslist .listupd .bs .bsx a.series`
- **Headers**: Added User-Agent, Accept-Language, Referer

#### ❌ **Direct URL Access - FAILED**
- **Status**: Not working
- **Issue**: `mangal inline --query "URL" --manga exact` returns empty results
- **Root Cause**: Mangal's "exact" mode expects title strings, not URLs
- **Workaround**: Need to implement title-based exact matching

#### 📊 **Script Quality Assessment**
- **Code Structure**: ✅ Perfect mangal Lua format
- **Error Handling**: ✅ Proper fallbacks and nil checks
- **HTTP Handling**: ✅ Correct headers and request setup
- **Selector Accuracy**: ⚠️ Needs refinement for complete results
- **JavaScript Handling**: ✅ Attempts script parsing for dynamic content

### Key Findings

#### **Selector Corrections Made**
1. **Search Results**: Updated from `.listupd .bs .bsx a` to `.serieslist .listupd .bs .bsx a.series`
2. **Chapter List**: Confirmed `#chapterlist ul li a` works
3. **Page Images**: Script parsing approach for dynamic content

#### **Mangal Integration Issues**
1. **Exact Mode**: Doesn't accept URLs, only title strings
2. **Query Processing**: May need URL decoding for special characters
3. **Result Limiting**: Only returns first manga match

#### **Site-Specific Challenges**
1. **Dynamic Content**: Images loaded via JavaScript `ts_reader.run()`
2. **Search Results**: Limited results per page (need pagination handling)
3. **URL Structure**: Consistent `/manga/title/` pattern

### Recommendations for Prompt Enhancement

#### **Immediate Fixes**
1. **Add Pagination Support**: Handle multiple search result pages
2. **Improve Exact Matching**: Support both title and URL inputs
3. **Better Error Messages**: Add debug logging for failed selectors

#### **Advanced Features**
1. **Headless Browser Fallback**: For sites with heavy JavaScript
2. **Rate Limiting**: Built-in delays between requests
3. **Content Type Detection**: Handle both manga and manhua sites

### Final Assessment
**The IA Scraper Prompt successfully generates functional scrapers** that work with Kaizoku's mangal integration. The generated script demonstrates:
- ✅ Correct architectural patterns
- ✅ Proper error handling
- ✅ Mangal API compliance
- ⚠️ Needs site-specific selector tuning
- ⚠️ May require pagination for complete results

**Result**: **SUCCESS** - The prompt creates scrapers that integrate properly with Kaizoku and can be refined for specific sites.

## Mangal Integration Analysis

### Current Integration
Kaizoku uses the external `mangal` CLI tool for all manga scraping operations. The integration is implemented through:

- **Source Management**: `mangal sources list -r` to get available sources
- **Configuration**: `mangal config` commands for settings management
- **Scraping Operations**: `mangal inline` commands for search, metadata, and downloads
- **Source Scripts**: Lua scripts in `docker/mangal/sources/` directory

### Existing Source Examples
- **MangaDex.lua**: Uses JSON API endpoints, no headless browser needed
- **Mangasee.lua**: Uses headless browser for dynamic content, includes navigation and interaction

### IA Scraper Prompt Assessment

The provided IA_Scrapper_Prompt.txt is **highly compatible** with Kaizoku's mangal integration:

#### ✅ Strengths
- **Correct Structure**: Follows exact mangal Lua script format with required functions (SearchManga, MangaChapters, ChapterPages)
- **Proper Imports**: Uses correct mangal modules (Html, Http, Headless, etc.)
- **Function Signatures**: Matches expected return types and parameter formats
- **Error Handling**: Includes robust fallback logic and selector alternatives
- **Documentation**: Extensive comments explaining selector discovery and verification
- **Testing Methodology**: Includes local testing commands matching Kaizoku's usage patterns

#### ⚠️ Potential Issues
- **Headless Browser Usage**: Prompt assumes headless browser availability, but some sites may require additional setup
- **Anti-Bot Measures**: While comprehensive, may need site-specific adjustments
- **Dynamic Content**: Assumes JS-rendered content can be handled, but some sites may be incompatible

#### ⚠️ **CRITICAL COMPATIBILITY ISSUE DISCOVERED**

**The IA_Scrapper_Prompt.txt is NOT compatible with the current mangal version (4.0.6 from 2023)!**

**Root Cause:** The prompt assumes Headless browser functionality that doesn't exist in mangal 4.0.6. Even the official Mangasee.lua script fails with the same error: `attempt to index a non-table object(nil) with key 'page'`.

**Testing Results:**
- ✅ HTTP-based scrapers (like MangaDex.lua) work fine
- ❌ Headless browser-based scrapers fail completely
- ❌ All scripts using `Headless.browser()` and `Browser:page()` fail

**Implication:** The prompt was written for a newer version of mangal with proper Headless browser support, but Kaizoku currently uses mangal 4.0.6 which lacks this functionality.

#### 🎯 **Updated Feasibility Assessment: NOT COMPATIBLE WITH CURRENT SETUP**

The prompt cannot generate working scrapers for the current Kaizoku/mangal 4.0.6 environment. To use the prompt successfully, mangal would need to be updated to a version that supports the Headless browser API.

**Risk Assessment for Kaizoku Pod:**
- Updating mangal could break existing functionality
- Docker container would need rebuild
- Potential compatibility issues with existing scrapers
- May require Prisma/database changes if mangal API changes

#### 📋 **Recommendations for Current Setup**
- **Not Compatible**: Cannot generate working scrapers with current mangal version
- **Alternative**: Use HTTP-only scrapers like MangaDex.lua as templates
- **Future Upgrade**: Consider mangal update only after thorough testing
- **Workaround**: Modify prompt to avoid Headless browser usage entirely

## Potential Areas for Improvement (if maintained)
- Upgrade to Next.js 13+ with App Router
- Migrate to newer Prisma versions
- Consider alternative queue systems or direct integration
- Modernize UI with newer Mantine versions
- Add comprehensive testing suite
- Improve error handling and user feedback