if (Sys.getenv('R_PLUMBER_HOME')==""){
  home_dir <- './src'
}else{
  home_dir <- Sys.getenv('R_PLUMBER_HOME')
}

#* Run scraping_suumo.R
#* @get /scraping_suumo
function() {
  source(paste0(home_dir, '/scripts/','scraping_suumo.R'))
}

#* Run hello.R
#* @get /say_hello
function(msg="") {
  source(paste0(home_dir, '/scripts/','hello.R'))
}
