import crawler
import gleam/bool
import gleam/dynamic
import sqlight

pub fn connect(name: String) -> Result(sqlight.Connection, sqlight.Error) {
  sqlight.open(name)
}

pub fn run_migrations(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  sqlight.exec(
    "
    create table if not exists websites (
			id integer primary key autoincrement not null,
			started_at integer not null,
			completed_at integer not null,
			status integer not null default 0,
			pattern_matched integer not null default 0,
			url text not null
		);",
    db,
  )
}

pub fn save_result(
  db: sqlight.Connection,
  result: crawler.CrawlResult,
) -> Result(Nil, sqlight.Error) {
  // actually not needed, as we don't read the result back
  let mock_decoder = dynamic.tuple2(dynamic.int, dynamic.int)

  case
    sqlight.query(
      "insert into websites (started_at, completed_at, status, pattern_matched, url) values (?, ?, ?, ?, ?)",
      on: db,
      with: [
        sqlight.int(result.started_at),
        sqlight.int(result.completed_at),
        sqlight.int(result.status_code),
        sqlight.int(result.pattern_matched |> bool.to_int),
        sqlight.text(result.url),
      ],
      expecting: mock_decoder,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(e)
  }
}
