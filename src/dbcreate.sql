create table casos(
  "city" text,
  "city_ibge_code" integer,
  "date" text,
  "epidemiological_week" integer,
  "estimated_population" integer,
  "estimated_population_2019" integer,
  "is_last" text,
  "is_repeated" text,
  "last_available_confirmed" integer,
  "last_available_confirmed_per_100k_inhabitants" real,
  "last_available_date" text,
  "last_available_death_rate" real,
  "last_available_deaths" integer,
  "order_for_place" integer,
  "place_type" text,
  "state" text,
  "new_confirmed" integer,
  "new_deaths" integer
);

.mode csv
.separator ,
.import data/casos.csv casos
.separator ;
.import data/estados.csv estados
.import data/regioes.csv regioes
