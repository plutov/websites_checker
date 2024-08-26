import gleam/io

pub type CrawlError {
  CrawlError(message: String)
}

pub type CrawlResult {
  CrawlResult(
    success: Bool,
    started_at: Int,
    completed_at: Int,
    status_code: Int,
    pattern_matched: Bool,
  )
}

pub fn crawl_url(
  url: String,
  pattern: String,
) -> Result(CrawlResult, CrawlError) {
  io.println("Crawling url: " <> url)
}
