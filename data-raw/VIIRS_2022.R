# faxina ------------------------------------------------------------------
library(ncdf4)
library(tidyverse)
library(lubridate)
library(purrr)
library(tictoc)
library(rgdal)
library(raster)
library(sf)

## extrair os diretórios
folders <- list.dirs("data-raw/",full.names = TRUE,
          recursive = TRUE)
folders <- folders %>%
  str_split(pattern = "//",simplify = TRUE)
ft <- folders %>%
  str_detect(pattern = "/")
folders <- folders[ft][-1]

def_pol <- function(x, y, pol){
  as.logical(sp::point.in.polygon(point.x = x,
                                  point.y = y,
                                  pol.x = pol[,1],
                                  pol.y = pol[,2]))
}

# criar a funçao para extraindo os dados do arquivo .NC
my_csv_creator <- function(path){
  ## listando os arquivos por folder
  ymd <- str_split(path,"_",simplify = TRUE)[4] %>%
    str_remove(pattern=".nc")
  nc = nc_open(path)
  co2 <- ncvar_get(nc, attributes(nc$var)$names[8])
  frp_mean <- ncvar_get(nc, attributes(nc$var)$names[6])
  ch4 <- ncvar_get(nc, attributes(nc$var)$names[9])
  co <- ncvar_get(nc, attributes(nc$var)$names[7])
  Lat <- ncvar_get(nc, attributes(nc$var)$names[2])
  Long <- ncvar_get(nc, attributes(nc$var)$names[1])
  dados<-data.frame(Lat,Long,ch4,co, co2, frp_mean, ymd)
  print(ymd)
  dados <- dados %>%
    mutate(
      flag_am = def_pol(Long, Lat, amazon_pol)
    ) %>% filter(flag_am)
}

## Criando o arquivo com os diretórios / caminhos
for(i in seq_along(folders)){
  files <- list.files(paste0("data-raw/",folders[i]))
  for(j in seq_along(files)){
   if(i==1 & j == 1) my_way <- paste0("data-raw/",folders[i],"/",files[j])
   else{
     va <- paste0("data-raw/",folders[i],"/",files[j])
     my_way<-c(my_way, va)
   }
  }
}

## tirano o polígono do bioma amazônia
amazonia_shp <-read_sf("shapes/Amazonia.shp")
amazon_pol <- amazonia_shp$geometry[[1]] %>% as.matrix()

## usando a função map para executar o mY-csv_creator
## para cada caminho em myway
# df_1 <- map_df(my_way[1:1000],my_csv_creator)
# readr::write_rds(df_1,"data/df_1.rds")

# df_2 <- map_df(my_way[1001:2000],my_csv_creator)
# readr::write_rds(df_2,"data/df_2.rds")

# df_3 <- map_df(my_way[2001:2901],my_csv_creator)
# readr::write_rds(df_3,"data/df_3.rds")


# ## Plotando os dados.
# df %>%
#   ggplot(aes(x=Long,y=Lat)) +
#   geom_point()


# write.csv(dados, "C:\\Users\\Documentos\\Documents\\dados\\VIIRS_2014_1.csv", append = FALSE)

# próxima análise ---------------------------------------------------------
library(tidyverse)
library(lubridate)
library(gridExtra)
library(ggpubr)
library(geobr)
library(sp)
library(trend)
library(gridExtra)
library(tsibble)
library(seasonal)
library(scales)
setwd("C:\\Users\\Documentos\\Documents\\dados\\2018")
dados <- read.csv("2018_1.csv")
head(dados)
tail(dados)
glimpse(df)
df <- dados  |>
  mutate(DATA = tsibble::yearmonth(paste(year, month)))
glimpse(df)

df_1 <- df |>
  group_by(year, month, DATA) |>
  summarise_all(mean)

#write.csv(df_1,"2016.csv")

ggplot(df_1, aes(x=DATA, group=2)) +
  geom_line(aes(y=co2),
            colour = "orange",linetype="solid",size=0.6)+
  geom_point(aes(y=co2),colour="orange", size=2)
