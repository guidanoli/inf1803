# Make sure the working directory is the repository root
# Load libraries
library(DBI)
library(scales)
library(rgdal)
library(ggplot2)
library(dplyr)
library(svglite)

# Connect to the database
# (Must have been previously created)
# See the README for more information
conn <- dbConnect(RSQLite::SQLite(), dbname="data/covid.db")

# Get some basic analytics from the data
total_casos <- dbGetQuery(conn, "select sum(new_confirmed) from casos where place_type is 'state'")[,1]
total_casos_rj_estado <- dbGetQuery(conn, "select sum(new_confirmed) from casos where state is 'RJ' and place_type is 'state'")[,1]
total_casos_rj_cidade <- dbGetQuery(conn, "select sum(new_confirmed) from casos where state is 'RJ' and city is 'Rio de Janeiro' and place_type is 'city'")[,1]
total_obitos <- dbGetQuery(conn, "select sum(new_deaths) from casos where place_type is 'state'")[,1]
total_obitos_rj_estado <- dbGetQuery(conn, "select sum(new_deaths) from casos where state is 'RJ' and place_type is 'state'")[,1]
total_obitos_rj_cidade <- dbGetQuery(conn, "select sum(new_deaths) from casos where state is 'RJ' and city is 'Rio de Janeiro' and place_type is 'city'")[,1]
letalidade <- total_obitos / total_casos
letalidade_rj_estado <- total_obitos_rj_estado / total_casos_rj_estado
letalidade_rj_cidade <- total_obitos_rj_cidade / total_casos_rj_cidade
habitantes <- dbGetQuery(conn, "select sum(hab) from (select estimated_population_2019 as hab from casos where place_type is 'state' group by state)")[,1]
habitantes_rj_estado <- dbGetQuery(conn, "select estimated_population_2019 as hab from casos where place_type is 'state' and state is 'RJ' group by state")[,1]
habitantes_rj_cidade <- dbGetQuery(conn, "select estimated_population_2019 as hab from casos where place_type is 'city' and state is 'RJ' and city is 'Rio de Janeiro' group by city")[,1]
mortalidade <- total_obitos / habitantes
mortalidade_rj_estado <- total_obitos_rj_estado / habitantes_rj_estado
mortalidade_rj_cidade <- total_obitos_rj_cidade / habitantes_rj_cidade

# Extracting tabular data...
# Here we use label_percent to export floating point numbers to CSV with 2 decimal places
top_cidades_brasil <- dbGetQuery(conn, "select * from (select state, city, cast(sum(new_confirmed) as float)/estimated_population_2019 as taxa, cast(sum(new_deaths) as float)/sum(new_confirmed) as letalidade, cast(sum(new_deaths) as float)/estimated_population_2019 as mortalidade from casos where place_type is 'city' group by city_ibge_code order by taxa desc limit 10) order by state, city")
write.csv2(top_cidades_brasil, file="data/top_cidades_brasil.csv", quote=FALSE)
top_cidades_rj <- dbGetQuery(conn, "select * from (select city, cast(sum(new_confirmed) as float)/estimated_population_2019 as taxa, cast(sum(new_deaths) as float)/sum(new_confirmed) as letalidade, cast(sum(new_deaths) as float)/estimated_population_2019 as mortalidade from casos where place_type is 'city' and state is 'RJ' group by city_ibge_code order by taxa desc limit 10) order by city")
write.csv2(top_cidades_rj, file="data/top_cidades_rj.csv", quote=FALSE)
casos_por_regiao <- dbGetQuery(conn, "select nomeregiao, sum(new_confirmed) as casos_acumulados from casos, estados, regioes where casos.state = estados.uf and estados.codigoregiao = regioes.codigoregiao and place_type is 'city' group by regioes.codigoregiao order by casos_acumulados desc;")
write.csv2(casos_por_regiao, file="data/casos_por_regiao.csv", quote=FALSE)
casos_por_estado_sudeste <- dbGetQuery(conn, "select estados.nomeestado, sum(new_confirmed) as casos_acumulados from casos, estados, regioes where casos.state = estados.uf and estados.codigoregiao = regioes.codigoregiao and regioes.nomeregiao is 'Sudeste' and place_type is 'city' group by estados.uf order by casos_acumulados desc;")
write.csv2(casos_por_estado_sudeste, file="data/casos_por_estado_sudeste.csv", quote=FALSE)
dados_por_estado <- dbGetQuery(conn, "select uf, total_casos, total_obitos, cast(total_obitos as float)/total_casos as letalidade, cast(total_obitos as float)/nhabs as mortalidade from (select state as uf, sum(new_confirmed) as total_casos, sum(new_deaths) as total_obitos, estimated_population_2019 as nhabs from casos where place_type is 'state' group by uf);")
write.csv2(dados_por_estado, file="data/dados_por_estado.csv", quote=FALSE)

# Plot Brazil data
brasil_shp <- readOGR(dsn="shapefiles", layer="BR_UF_2020")
brasil_df <- fortify(brasil_shp)
casos_por_estado <- dbGetQuery(conn, "select codigoibge, sum(new_confirmed) as total_casos from casos, estados where place_type is 'state' and casos.state = estados.uf group by state;")
index <- 0
uf_codigos <- data.frame(matrix(nrow=0, ncol=2))
colnames(uf_codigos) <- c('id', 'codigoibge')
for (uf in brasil_shp$CD_UF) {
  uf_codigos <- rbind(uf_codigos, data.frame(id=index, codigoibge=uf))
  index <- index + 1
}
brasil_df$id <- as.double(brasil_df$id)
brasil_df <- left_join(brasil_df, uf_codigos, by="id")
brasil_df <- left_join(brasil_df, casos_por_estado, by="codigoibge")
mapa_brasil <- ggplot(brasil_df, aes(x=long, y=lat, group=group))+
  geom_polygon(aes(fill=total_casos), color="black")
mapa_brasil <- mapa_brasil + scale_fill_gradient(name = "Número de casos", low = "white", high = "red", na.value = "grey50", labels = comma, trans = "log")+
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        rect = element_blank())
ggsave(file="plots/brasil.svg", plot=mapa_brasil)

# Plot Rio de Janeiro data
rj_shp <- readOGR(dsn="shapefiles", layer="RJ_Municipios_2020")
rj_df <- fortify(rj_shp)
casos_por_cidade_rj <- dbGetQuery(conn, "select city_ibge_code as codigoibge, sum(new_confirmed) as total_casos from casos where place_type is 'city' and state is 'RJ' and city_ibge_code is not '' group by city_ibge_code;")
index <- 0
cidade_codigos <- data.frame(matrix(nrow=0, ncol=2))
colnames(cidade_codigos) <- c('id', 'codigoibge')
for (mun in rj_shp$CD_MUN) {
  cidade_codigos <- rbind(cidade_codigos, data.frame(id=index, codigoibge=mun))
  index <- index + 1
}
rj_df$id <- as.double(rj_df$id)
rj_df <- left_join(rj_df, cidade_codigos, by="id")
rj_df$codigoibge <- as.integer(as.character(rj_df$codigoibge))  # There might be a better way to do this :-)
rj_df <- left_join(rj_df, casos_por_cidade_rj, by="codigoibge")
mapa_rj <- ggplot(rj_df, aes(x=long, y=lat, group=group))+
  geom_polygon(aes(fill=total_casos), color="black")
mapa_rj <- mapa_rj + scale_fill_gradient(name = "Número de casos", low = "white", high = "red", na.value = "grey50", labels = comma, trans = "log")+
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        axis.title.x = element_blank(),
        rect = element_blank())
ggsave(file="plots/rj.svg", plot=mapa_rj)

# Get all dates indexed by id (useful for scatter plots)
datas <- dbGetQuery(conn, "select date from casos group by date;")
datas <- mutate(datas, id=row_number())  # Add row id to new column called 'id'

# Scatter plot on daily cases
casos_diarios <- dbGetQuery(conn, "select date, sum(new_confirmed) as total_casos from casos where place_type is 'state' group by date;")
casos_diarios_rj <- dbGetQuery(conn, "select date, sum(new_confirmed) as total_casos from casos where place_type is 'city' and state is 'RJ' group by date;")
casos_diarios <- left_join(casos_diarios, datas, by="date")
casos_diarios_rj <- left_join(casos_diarios_rj, datas, by="date")
dispersao_casos <- ggplot(NULL, aes(x = id, y = total_casos))+
  geom_point(data = casos_diarios, aes(color = "Brasil"))+
  geom_line(data = casos_diarios, aes(color = "Brasil"))+
  geom_point(data = casos_diarios_rj, aes(color = "RJ"))+
  geom_line(data = casos_diarios_rj, aes(color = "RJ"))+
  labs(title = "Casos diários de COVID-19", x = "Dia", y = "Número de casos novos")+
  scale_color_manual(name = "Região", breaks = c("Brasil", "RJ"), values = c("darkgreen", "darkblue"))
ggsave(file="plots/scatter_casos.svg", plot=dispersao_casos)

# Scatter plot on daily deaths
obitos_diarios_mm <- dbGetQuery(conn, "select date, avg(daily_deaths) over(order by date rows between 5 preceding and current row) as daily_deaths_avg from (select date, sum(new_deaths) as daily_deaths from casos where place_type is 'state' group by date);")
obitos_diarios_rj_mm <- dbGetQuery(conn, "select date, avg(daily_deaths) over(order by date rows between 5 preceding and current row) as daily_deaths_avg from (select date, sum(new_deaths) as daily_deaths from casos where place_type is 'city' and state is 'RJ' group by date);")
obitos_diarios_mm <- left_join(obitos_diarios_mm, datas, by="date")
obitos_diarios_rj_mm <- left_join(obitos_diarios_rj_mm, datas, by="date")
dispersao_obitos <- ggplot(NULL, aes(x = id, y = daily_deaths_avg))+
  geom_point(data = obitos_diarios_mm, aes(color = "Brasil"))+
  geom_point(data = obitos_diarios_rj_mm, aes(color = "RJ"))+
  labs(title = "Óbitos diários de COVID-19", x = "Dia", y = "Número de óbitos novos")+
  scale_color_manual(name = "Região", breaks = c("Brasil", "RJ"), values = c("darkgreen", "darkblue"))
ggsave(file="plots/scatter_obitos.svg", plot=dispersao_obitos)

# Make trend analysis on daily deaths
last_2weeks <- tail(obitos_diarios_mm, n=14)$daily_deaths_avg
rate <- last_2weeks[14] / last_2weeks[1] - 1
print(sprintf("Tendência de óbitos diários no Brasil: %.2f%%", rate*100))
if (rate < -0.15) {
  print("Em queda")
} else if (rate > 0.15) {
  print("Em crescimento")
} else {
  print("Estável")
}

# Make same analysis but on Rio
last_2weeks <- tail(obitos_diarios_rj_mm, n=14)$daily_deaths_avg
rate <- last_2weeks[14] / last_2weeks[1] - 1
print(sprintf("Tendência de óbitos diários no Rio de Janeiro: %.2f%%", rate*100))
if (rate < -0.15) {
  print("Em queda")
} else if (rate > 0.15) {
  print("Em crescimento")
} else {
  print("Estável")
}

# Accumulated cases and deaths
casos_acumulados_rj <- dbGetQuery(conn, "select date, sum(new_confirmed) over (rows unbounded preceding) as casos_ac from casos where place_type is 'state' and state is 'RJ' group by date;")
obitos_acumulados_rj <- dbGetQuery(conn, "select date, sum(new_deaths) over (rows unbounded preceding) as obitos_ac from casos where place_type is 'state' and state is 'RJ' group by date;")
casos_acumulados_rj <- left_join(casos_acumulados_rj, datas, by="date")
obitos_acumulados_rj <- left_join(obitos_acumulados_rj, datas, by="date")
dispersao_casos_obitos_rj <- ggplot(NULL)+
  geom_point(data = casos_acumulados_rj, aes(color = "Casos acumulados", x = id, y = casos_ac))+
  geom_line(data = casos_acumulados_rj, aes(color = "Casos acumulados", x = id, y = casos_ac))+
  geom_point(data = obitos_acumulados_rj, aes(color = "Óbitos acumulados", x = id, y = obitos_ac))+
  geom_line(data = obitos_acumulados_rj, aes(color = "Óbitos acumulados", x = id, y = obitos_ac))+
  labs(title = "Casos e óbitos acumulados de COVID-19 no estado do Rio de Janeiro", x = "Dia", y = "Número de casos/óbitos")+
  scale_color_manual(name = "", breaks = c("Casos acumulados", "Óbitos acumulados"), values = c("darkblue", "red"))
ggsave(file="plots/scatter_obitos_casos_acumulados_rj.svg", plot=dispersao_casos_obitos_rj)