
os_type <- function() {
  .Platform$OS.type
}

get_tool <- function (prog) {
  if (os_type() == "windows") prog <- paste0(prog, ".exe")

  exe <- system.file(package = "zip", "bin", .Platform$r_arch, prog)
    if (exe == "") {
      pkgpath <- system.file(package = "zip")
      if (basename(pkgpath) == "inst") pkgpath <- dirname(pkgpath)
      exe <- file.path(pkgpath, "src", "tools", prog)
      if (!file.exists(exe)) return("")
    }
  exe
}

unzip_exe <- function() {
  get_tool("unzip")
}
