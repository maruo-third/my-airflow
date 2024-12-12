library(tidyverse)
library(rvest)
theme_set(theme_grey(base_size = 12, base_family = "HiraKakuPro-W3"))

df.urls <- tibble(
    search_condition = c("中古戸建", "土地", "リノベ素材"),
    url = c(
      'https://suumo.jp/jj/common/ichiran/JJ901FC004/?pc=100&seniFlg=1&ar=030&ta=14&sc=14208&scTmp=14208&kwd=&bs=021&cb=0.0&ct=9999999&kb=0&kt=5000&km=1&xb=90&xt=9999999&et=9999999&cn=25&newflg=0&pn=',
      'https://suumo.jp/jj/common/ichiran/JJ901FC004/?pc=100&seniFlg=1&ar=030&ta=14&sc=14208&scTmp=14208&kwd=&bs=030&cb=0.0&ct=9999999&kb=0&kt=4000&km=1&xb=90&xt=9999999&et=9999999&cn=9999999&newflg=0&pn=',
      'https://suumo.jp/jj/common/ichiran/JJ901FC004/?pc=100&seniFlg=1&ar=030&ta=14&sc=14208&scTmp=14208&kwd=&bs=021&cb=0.0&ct=9999999&kb=0&kt=4000&km=1&xb=90&xt=9999999&et=9999999&cn=9999999&newflg=0&pn='
    )
  )
xpath_base <- '//*[@id="js-bukkenList"]/form/ul[*]/li[*]/div[2]'
xpaths <- list(
  house_type = paste0(xpath_base, '/div[1]/span[1]'),
  title = paste0(xpath_base, '/div[1]/h2/a'),
  address = paste0(xpath_base, '/div[2]/div[1]/div/div[2]/div[1]/div[1]/table/tbody/tr[2]/td[1]/div'),
  area_land = paste0(xpath_base, '/div[2]/div[1]/div/div[2]/div/div[2]/table/tbody/tr[2]/td[2]/div/dl[1]'),
  area_house = paste0(xpath_base, '/div[2]/div[1]/div/div[2]/div/div[2]/table/tbody/tr[2]/td[2]/div/dl[2]'),
  arrangement = paste0(xpath_base, '/div[2]/div[1]/div/div[2]/div/div[2]/table/tbody/tr[2]/td[2]/div/dl[3]'),
  constructed_in = paste0(xpath_base, '/div[2]/div[1]/div/div[2]/div/div[2]/table/tbody/tr[2]/td[3]/div')
)

for (j in 1:dim(df.urls)[1]){
  for (i in 1:1) {
    page_num <- i
    target_url <- paste0(
      df.urls$url[j],
      as.character(page_num)
    )
    
    page <- read_html(target_url)
    
    if(df.urls$search_condition[j] == "土地"){
      area_house <- NA
      arrangement <- NA
      constructed_in <- NA 
    } else {
      area_house <- html_nodes(
        page,
        xpath=xpaths$area_house
      ) %>% html_text()
      
      arrangement <- html_nodes(
        page,
        xpath=xpaths$arrangement
      ) %>% html_text()
      
      constructed_in <- html_nodes(
        page,
        xpath=xpaths$constructed_in
      ) %>% html_text()
    }
    
    df.page <- tibble(
      search_condition = df.urls$search_condition[j],
      
      house_type = html_nodes(
        page,
        xpath=xpaths$house_type
      ) %>% html_text(),
      
      title = html_nodes(
        page,
        xpath=xpaths$title
      ) %>% html_text(),
      
      address = html_nodes(
        page,
        xpath=xpaths$address
      ) %>% html_text(),
      
      area_land = html_nodes(
        page,
        xpath=xpaths$area_land
      ) %>% html_text(),
      
      area_house = area_house,
      
      arrangement = arrangement,
      
      constructed_in = constructed_in,
      
      link_to_detail = html_nodes(
        page,
        xpath=xpaths$title
      ) %>% html_attr('href')
      
    ) %>%
      mutate(
        address = str_extract(address, '神奈川県.+'),
        area_land = str_extract(area_land, '[\\d\\.]+(?=m2)') %>% as.numeric(),
        area_house = str_extract(area_house, '[\\d\\.]+(?=m2)') %>% as.numeric(),
        arrangement = str_extract(arrangement, '\\d[A-Z].+'),
        constructed_in = if_else(
          is.na(constructed_in), as.character(NA),
          paste0(
            str_extract(constructed_in, '\\d{4}'),'-',
            str_extract(constructed_in, '\\d{1,2}(?=月)') %>% str_pad(2, pad = '0'),'-',
            '01'
          )
        ),
        price_million = as.numeric(str_remove(str_extract(title, '\\d+万円$'), '万円')) / 100,
        link_to_detail = paste0('https://suumo.jp', link_to_detail)
      )
    
    if(i==1){
      df.pages <- df.page
    }else{
      df.pages <- df.pages %>% union(df.page)
    }
  }
  
  if(j==1){
    df.pages.conditions <- df.pages
  }else{
    df.pages.conditions <- df.pages.conditions %>% union(df.pages)
  }
}

df.pages.conditions <- df.pages.conditions %>%
  filter(!(
    search_condition == 'リノベ素材' &
    constructed_in < as.Date('1981-08-01')
  ))

df.pages.conditions <- df.pages.conditions %>% mutate(
  dealer = as.character(NA)
)

for (i in 1:length(df.pages.conditions$link_to_detail)){
  target_url <- df.pages.conditions$link_to_detail[i]
  
  tryCatch({
    df.pages.conditions$dealer[i] <- read_html(target_url) %>%
      html_nodes(xpath='//*[@id="topContents"]/div[2]/div[1]/div[2]/p[4]') %>% 
      html_text()
  }, error = function(e){
    df.pages.conditions$dealer[i] <- as.character(NA)
  })
  
  Sys.sleep(0.2)
}

dir.create(paste0(home_dir, '/data'))
df.pages.conditions %>% write_csv(
  paste0(
    home_dir,
    '/data/houses_',
    lubridate::today() %>% as.character() %>% str_replace_all('-', ''),
    '.csv'
  ),
  na = ''
)

