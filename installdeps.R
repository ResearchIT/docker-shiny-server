# set cran mirror
local({
r = getOption("repos")
r["CRAN"] = "https://mirror.las.iastate.edu/CRAN"
options(repos = r)
})

# function to install r-requirements.txt
# adapted from https://gist.github.com/cannin/6b8c68e7db19c4902459
installdeps <- function(file="/opt/app-root/src/r-requirements.txt", lib="/opt/app-root/src/R_libs") {

  # Install packages
  if(!is.null(file)) {
    packages <- utils:::read.table(file, stringsAsFactors = FALSE)
    packages <- packages$V1
  }

  if("devtools" %in% rownames(utils:::installed.packages())) {
    require(devtools)
  } else {
    utils:::install.packages("devtools", lib=lib)
  }

  if("stringr" %in% rownames(utils:::installed.packages())) {
    require(stringr)
  } else {
    utils:::install.packages("stringr", lib=lib)
  }

  for(package in packages) {
    tmp <- strsplit(package, .Platform$file.sep)[[1]]
    packageName <- tmp[length(tmp)]

    if(!(packageName %in% rownames(utils:::installed.packages()))) {
      if(package %in% rownames(utils:::available.packages())) {
        utils:::install.packages(package, lib=lib)
      } else {
        require(BiocManager)
        if(length(BiocManager::available(package))>0) {
          BiocManager::install("TissueEnrich")
        }
      }
    }
  }
}

installdeps()
