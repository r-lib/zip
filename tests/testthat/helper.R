
df <- function(key, file, dir = FALSE) {
  data.frame(
    stringsAsFactors = FALSE,
    key = key,
    file = file,
    dir = dir
  )
}
