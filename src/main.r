library(DBI)
conn <- dbConnect(RSQLite::SQLite(), dbname="data/covid.db")
total_casos <- dbGetQuery(conn, "select sum(new_confirmed) from casos where place_type is 'city'")[,1]
total_casos_rj_estado <- dbGetQuery(conn, "select sum(new_confirmed) from casos where state is 'RJ' and place_type is 'state'")[,1]
total_casos_rj_cidade <- dbGetQuery(conn, "select sum(new_confirmed) from casos where state is 'RJ' and city is 'Rio de Janeiro' and place_type is 'city'")[,1]
total_obitos <- dbGetQuery(conn, "select sum(new_deaths) from casos where place_type is 'city'")[,1]
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