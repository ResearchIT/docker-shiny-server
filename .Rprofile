
# set cran mirror
local({
r = getOption("repos")
r["CRAN"] = "https://mirror.las.iastate.edu/CRAN"
options(repos = r)
})

# function to install r-requirements.txt
# adapted from https://gist.github.com/cannin/6b8c68e7db19c4902459
installPackages <- function(file="r-requirements.txt", lib="~/R/") {
  
  # Install packages 
  if(!is.null(file)) {
    packages <- read.table(file, stringsAsFactors = FALSE)
    packages <- packages$V1
  }
  
  if("devtools" %in% rownames(installed.packages())) {
    require(devtools)	  
  } else {
    install.packages("devtools", lib=lib)  
  }
  
  if("stringr" %in% rownames(installed.packages())) {
    require(stringr)	  
  } else {
    install.packages("stringr", lib=lib)  
  }

  for(package in packages) {
    tmp <- strsplit(package, .Platform$file.sep)[[1]]
    packageName <- tmp[length(tmp)]

    if(!(packageName %in% rownames(installed.packages()))) {
      if(package %in% rownames(available.packages())) {
        install.packages(package, lib=lib)
      } 
    }
  }
}

# install r-requirements.txt
installPackages(file="/opt/app-root/src/r-requirements.txt", lib="/opt/app-root/src/R_libs")