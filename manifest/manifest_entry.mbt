///|
/// Declarative entry content loaded into a Lepus application window.
pub(all) enum AppEntry {
  Html(String)
  Url(String)
  File(String)
  Asset(String)
} derive(Debug, Eq)

///|
pub impl Show for AppEntry with output(self, logger) {
  match self {
    Html(value) => {
      logger.write_string("Html(")
      logger.write_object(value)
      logger.write_string(")")
    }
    Url(value) => {
      logger.write_string("Url(")
      logger.write_object(value)
      logger.write_string(")")
    }
    File(value) => {
      logger.write_string("File(")
      logger.write_object(value)
      logger.write_string(")")
    }
    Asset(value) => {
      logger.write_string("Asset(")
      logger.write_object(value)
      logger.write_string(")")
    }
  }
}
