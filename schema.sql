-- исхожу из предположения: если юзер не нашел прямой маршрут до нужной точки, он может сделать два заказа и получить два билета
-- со стороны приложения это можно объединить в один процесс, но со стороны данных будет создано несколько билетов
-- Даже если юзер всего лишь один, пассажиров он может зарегистрировать несколько. Для каждого пассажира будет создан отдельный билет

-- В системе есть станции и маршруты. Маршруты состоят из начальной станции и конечной. Путь и порядок маршрута формируется промежуточной таблицей
-- Пассажир создает билет. Билет привязан к маршруту и к поезду маршрута. Билет определяет резервацию за пассажиром выбранного места, исходя из первого предположения,
-- от начальной станции до конечной

-- юзер зарегистрированный в системе
-- каждый юзер может завести пассажиров, которых и укажет при оформлении билета (к примеру, родитель и его дети)
create table "users" (
  "id" serial primary key,
  "email" varchar not null
);


-- справочник станций
create table "stations" (
  "id" integer primary key,
  "city" varchar,
  "name" varchar
);

-- справочник маршрутов
create table "routes" (
  "id" integer primary key,
  "source_station" integer not null references stations("id"),
  "destination_station" integer not null references stations("id")
);

-- пассажир, на чье имя выписывается билет и производится резервация
create table "passengers" (
  "id" serial primary key,
  "user_id" integer not null references users("id"),
  "name" varchar not null,
  "date_of_birth" date not null,
  "phone" varchar not null,
  "email" varchar not null
);

-- справочник поездов, между поездом и маршрутом связь m-2-m
create table "trains" (
  "id" integer primary key
);

-- m-2-m поездов к маршрутам, реализация обсуждаема, пока просто проиллюстрировать связи 
create table routes_trains (
  "route_id" integer not null references routes("id"),
  "train_id" integer not null references trains("id"),

  primary key ("route_id", "train_id")
);


-- места в поезде. информацию о тарифе и стоимости можно вынести в отдельную таблицу
-- на места производится резервация
-- Так как пассажир может сойти с поезда на промежуточной станции, то поле "available" не подойдет
-- т.к. остальные пользователи не смогут зарезервировать это место
-- к примеру маршрут москва-нижний новгород-казан, пользователь резервирует москва-нижний новгород, но место москва-казань уже будет не доступно остальным
-- нужно уточнить как разрешать подобную ситуацию у клиента, и какое ожидаемое поведение нужно
-- Для статистики по свободным местам можно вынести данные либо в таблицу статистики для trains, либо, к примеру, создать вьюхи на эти данные
create table "train_seats" (
  "id" integer primary key,
  "train_id" integer not null,
  "number" integer not null,
  "base_fare" decimal not null,
  -- "available" bool not null, -- см. комментарий выше
  "type" varchar not null
);


create table "trains_train_seats" (
  "train_seat_id" integer not null references train_seats("id"),
  "train_id" integer not null references trains("id"),
  
  primary key ("train_seat_id", "train_id")
);


-- билет с основной информацией о поездке, может использоваться как замена модели order
create table "tickets" (
  "id" integer primary key,
  "user_id" integer not null references users("id"),
  "passenger_id" integer not null references passengers("id"),
  "total_price" decimal not null,
  -- разделение date/time на случай нужды в партиционировании таблиц
  "departure_date" date not null,
  "departure_time" time not null,
  "arrival_date" date not null,
  "arrival_time" time not null, 
  "source_station" integer not null references stations("id"),
  "destination_station" integer not null references stations("id"),
  "route_id" integer not null references routes("id"),
  -- Если система бронирования будет несколько сложней, то это можно вынести в таблицу reservations
  -- в таком варианте логика резервации переносится на тикеты, т.е. приложению нужно будет проверить билеты по дате и месту,
  -- чтобы показать доступные места для пассажиров, садящихся на поезд, к примеру, в середине маршрута
  "seat_id" integer not null references train_seats("id")
);

-- остановки внутри маршрута, упорядоченные по order 
-- К каждой станции можно добавить дополнительную стоимость в зависимости от маршрута/поезда.
-- также эту информацию можно вынести в отдельную таблицу тарифов, либо привязать конкретно к поезду
-- для простоты добавил тут 
create table "stops" (
  "route_id" integer not null references routes("id"),
  "station_id" integer not null references stations("id"),
  "order" integer not null,
  "arrival_datetime" timestamp with time zone not null,
  "departure_datetime" timestamp with time zone not null, 
  "intersation_fare" decimal not null,

  primary key ("route_id", "station_id")
);
