#' Automated leaf area analysis
#'
#' @param path.imagej
#' @param set.memory
#' @param set.directory
#' @param distance.pixel
#' @param known.distance
#' @param trim.pixel
#' @param low.circ
#' @param upper.circ
#' @param low.size
#' @param upper.size
#' @param prefix
#' @param log
#' @param check.image
#' @param save.image
#'
#' @return
#' @export
#'
#' @examples
run.ij <- function (path.imagej = NULL, set.memory = 4, set.directory,
          distance.pixel = 826, known.distance = 21, trim.pixel = 20,
          low.circ = 0, upper.circ = 1, low.size = 0.7, upper.size = "Infinity",
          prefix = "\\.|-", log = F, check.image = F, save.image = F)
{
  file.list <- list.files(set.directory)
  file.list <- file.list[grep(".jpeg$|.jpg$|.JPEG$|.JPG$|.tif$|.tiff$|.Tif$|.Tiff$",
                              file.list)]
  if (length(file.list) == 0)
    return("No images in the directory")
  temp.slash <- substr(set.directory, nchar(set.directory),
                       nchar(set.directory))
  if (temp.slash != "/" & temp.slash != "\\") {
    set.directory <- paste(set.directory, "/", sep = "")
  }
  circ.arg <- paste(low.circ, upper.circ, sep = "-")
  size.arg <- paste(low.size, upper.size, sep = "-")
  os <- .Platform$OS.type
  if (is.null(path.imagej) == T) {
    imagej <- find.ij(ostype = .Platform$OS.type)
    if (imagej == "ImageJ not found")
      return("ImageJ not found")
    else path.imagej <- imagej
  }
  if (os == "windows") {
    path.imagej <- gsub("/", "\\\\", path.imagej)
    if (file.exists(paste(path.imagej, "ij.jar", sep = "")) !=
        T & file.exists(paste(path.imagej, "ij.jar", sep = "/")) !=
        T) {
      warning("ij.jar was not found. Specify the correct path to ImageJ directory or reinstall ImageJ bundled with Java")
      return("ImageJ not found")
    }
    else if (file.exists(paste(path.imagej, "jre/bin/java.exe",
                               sep = "")) != T & file.exists(paste(path.imagej,
                                                                   "jre/bin/java.exe", sep = "/")) != T) {
      warning("java was not found. Specify the correct path to ImageJ directory or reinstall ImageJ bundled with Java")
      return("ImageJ not found")
    }
  }
  else {
    unix.check <- Sys.info()["sysname"]
    if (unix.check == "Linux") {
      #look <- "ImageJ"
      if (file.exists(paste(path.imagej, "ij.jar",
                            sep = "")) != T & file.exists(paste(path.imagej,
                                                                "ij.jar", sep = "/")) != T) {
        warning("Specify the correct path to ImageJ")
        return("ImageJ not found")
      }
    }
    else if (unix.check == "Darwin") {
      if (file.exists(paste(path.imagej, "Contents/Resources/Java/ij.jar",
                            sep = "")) != T & file.exists(paste(path.imagej,
                                                                "Contents/Resources/Java/ij.jar", sep = "/")) !=
          T) {
        warning("Specify the correct path to ImageJ.app")
        return("ImageJ not found")
      }
    }
  }
  if (os == "windows") {
    temp <- paste(tempdir(), "\\", sep = "")
    temp <- gsub("\\\\", "\\\\\\\\", temp)
  }
  else {
    temp <- paste(tempdir(), "/", sep = "")
  }
  if (save.image == T)
    macro <- paste("dir = getArgument;\n dir2 = \"", temp,
                   "\";\n list = getFileList(dir);\n open(dir + list[0]);\n run(\"Set Scale...\", \"distance=",
                   distance.pixel, " known=", known.distance, " pixel=1 unit=cm global\");\n for (i=0;\n i<list.length;\n i++) { open(dir + list[i]);\n width = getWidth() - ",
                   trim.pixel, ";\n height = getHeight() -", trim.pixel,
                   " ;\n run(\"Canvas Size...\", \"width=\" + width + \" height=\" + height + \" position=Bottom-Center\");\n run(\"8-bit\");\n run(\"Threshold...\");\n setAutoThreshold(\"Minimum\");\n run(\"Analyze Particles...\", \"size=",
                   size.arg, " circularity=", circ.arg, " show=Masks display clear record\");\n saveAs(\"Measurements\", dir2+list[i]+\".txt\");\n saveAs(\"tiff\", dir+list[i]+ \"_mask.tif\");\n}",
                   sep = "")
  else macro <- paste("dir = getArgument;\n dir2 = \"", temp,
                      "\";\n list = getFileList(dir);\n open(dir + list[0]);\n run(\"Set Scale...\", \"distance=",
                      distance.pixel, " known=", known.distance, " pixel=1 unit=cm global\");\n for (i=0;\n i<list.length;\n i++) { open(dir + list[i]);\n width = getWidth() - ",
                      trim.pixel, ";\n height = getHeight() -", trim.pixel,
                      " ;\n run(\"Canvas Size...\", \"width=\" + width + \" height=\" + height + \" position=Bottom-Center\");\n run(\"8-bit\");\n run(\"Threshold...\");\n setAutoThreshold(\"Minimum\");\n run(\"Analyze Particles...\", \"size=",
                      size.arg, " circularity=", circ.arg, " show=Masks display clear record\");\n saveAs(\"Measurements\", dir2+list[i]+\".txt\");\n}",
                      sep = "")
  tempmacro <- paste(tempfile("macro"), ".txt", sep = "")
  write(macro, file = tempmacro)
  if (check.image == T) {
    exe <- "-macro "
    wait = FALSE
  }
  else {
    exe <- "-batch "
    wait = TRUE
  }
  if (os == "windows") {
    if (length(strsplit(set.directory, " ")[[1]]) > 1) {
      bat <- paste("pushd ", path.imagej, "\n jre\\bin\\java -jar -Xmx",
                   set.memory, "g ij.jar ", exe, tempmacro, " \"",
                   set.directory, "\"\n pause\n exit", sep = "")
    }
    else bat <- paste("pushd ", path.imagej, "\n jre\\bin\\java -jar -Xmx",
                      set.memory, "g ij.jar ", exe, tempmacro, " ", set.directory,
                      "\n pause\n exit", sep = "")
    tempbat <- paste(tempfile("bat"), ".bat", sep = "")
    write(bat, file = tempbat)
    shell(tempbat, wait = wait)
  }
  else {
    temp.slash2 <- substr(path.imagej, nchar(path.imagej),
                          nchar(path.imagej))
    if (temp.slash2 != "/") {
      path.imagej <- paste(path.imagej, "/", sep = "")
    }
    set.directory <- gsub(" ", "\\ ", set.directory, fixed = TRUE)
    unix.check <- Sys.info()["sysname"]
    if (unix.check == "Linux") {
      system(paste("java -Xmx", set.memory, "g -jar ",
                   path.imagej, "ij.jar -ijpath ", path.imagej,
                   " ", exe, tempmacro, " ", set.directory, sep = ""),
             wait = wait)
    }
    else {
      system(paste("java -Xmx", set.memory, "g -jar ",
                   path.imagej, "Contents/Resources/Java/ij.jar -ijpath ",
                   path.imagej, " ", exe, tempmacro, " ", set.directory,
                   sep = ""), wait = wait)
    }
  }
  if (check.image == T) {
    ans <- readline("Do you want to close ImageJ? Press any keys when you finish cheking analyzed images.")
    if (os == "windows")
      suppressWarnings(shell("taskkill /f /im \"java.exe\""))
    else system("killall java")
  }
  res <- LeafArea::resmerge.ij(path = temp, prefix = prefix)
  if (log == T)
    res2 <- LeafArea::readtext.ij(path = temp)
  cd <- getwd()
  setwd(temp)
  unlink(list.files(temp))
  setwd(cd)
  if (log == T)
    return(list(summary = res, each.image = res2))
  else return(res)
}
