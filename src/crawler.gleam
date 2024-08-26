import birl
import gleam/hackney
import gleam/http/request
import gleam/io
import gleam/string

pub type CrawlResult {
  CrawlResult(
    url: String,
    success: Bool,
    started_at: Int,
    completed_at: Int,
    status_code: Int,
    pattern_matched: Bool,
  )
}

// It always returns a CrawlResult, even if there is an error.
pub fn crawl_url(url: String, pattern: String) -> CrawlResult {
  let started_at = birl.now() |> birl.to_unix
  io.println("Crawling url: " <> url)

  let assert Ok(req) = request.to(url)

  case hackney.send(req) {
    Ok(response) -> {
      let pattern_matched =
        pattern != "" && response.body |> string.contains(pattern)

      CrawlResult(
        url: url,
        success: True,
        started_at: started_at,
        completed_at: birl.now() |> birl.to_unix,
        status_code: response.status,
        pattern_matched: pattern_matched,
      )
    }
    Error(_) -> {
      CrawlResult(
        url: url,
        success: False,
        started_at: started_at,
        completed_at: birl.now() |> birl.to_unix,
        status_code: 0,
        pattern_matched: False,
      )
    }
  }
}
