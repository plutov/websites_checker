import config
import crawler
import database
import gleam/erlang/os
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import sqlight

pub fn main() {
  let db_name = get_db_name()
  let config_filename = get_config_filename()

  let c = case config.load(config_filename) {
    Ok(config) -> {
      io.println(string.append(
        "Config loaded successfully, websites: ",
        list.length(config.websites) |> int.to_string,
      ))
      config
    }
    Error(e) -> panic as string.append("Failed to load config: ", e.message)
  }

  // Run database migrations
  let db_conn = case database.connect(db_name) {
    Ok(conn) -> conn
    Error(e) ->
      panic as string.append("Failed to connect to database: ", e.message)
  }

  case database.run_migrations(db_conn) {
    Ok(_) -> io.println("Database migrations ran successfully")
    Error(e) -> panic as string.append("Failed to run migrations: ", e.message)
  }

  // Start process for each website
  list.each(c.websites, fn(w) {
    process.start(fn() { process_website_recursively(db_conn, w) }, True)
  })

  process.sleep_forever()
}

fn get_db_name() -> String {
  os.get_env("DB_NAME")
  |> result.unwrap("./websites.sqlite3")
}

fn get_config_filename() -> String {
  os.get_env("CONFIG")
  |> result.unwrap("./websites.yaml")
}

fn process_website_recursively(
  db_conn: sqlight.Connection,
  website: config.Website,
) {
  let result = crawler.crawl_url(website.url, website.pattern)
  case database.save_result(db_conn, result) {
    Ok(_) ->
      io.println(string.append("Result saved successfully: ", website.url))
    Error(e) -> io.println(string.append("Failed to save result: ", e.message))
  }
  process.sleep(website.interval * 1000)
  process_website_recursively(db_conn, website)
}
