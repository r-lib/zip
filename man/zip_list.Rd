% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zip.R
\name{zip_list}
\alias{zip_list}
\title{List Files in a 'zip' Archive}
\usage{
zip_list(zipfile)
}
\arguments{
\item{zipfile}{Path to an existing ZIP file.}
}
\value{
A data frame with columns: \code{filename}, \code{compressed_size},
\code{uncompressed_size}, \code{timestamp}, \code{permissions}, \code{crc32}, \code{offset} and
\code{type}. \code{type} is one of \code{file}, \code{block_device}, \code{character_device},
\code{directory}, \code{FIFO}, \code{symlink} or \code{socket}.
}
\description{
List Files in a 'zip' Archive
}
\details{
Note that \code{crc32} is formatted using \code{as.hexmode()}. \code{offset} refers
to the start of the local zip header for each entry. Following the approach
of \code{seek()} it is stored as a \code{numeric} rather than an \code{integer} vector and
can therefore represent values up to \code{2^53-1} (9 PB).
}
\concept{zip/unzip functions}
