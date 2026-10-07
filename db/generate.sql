-- Builds the dataset every demo serves and every demo's tests read, in PostgreSQL.
--
-- db/postgres.sh loads it into the demo_template database; each benchmark run and each test run
-- clones a fresh database from that template (see db/postgres.sh reset).
--
--   psql -v ON_ERROR_STOP=1 -d demo_template -f db/generate.sql
--
-- Fully deterministic: no random(), so the same rows come out every time.
--
-- 100 categories in 3 levels. Ids spell the path: 2 Technology > 21 Artificial Intelligence >
-- 211 Large Language Models. Branches are deliberately uneven; 53 Television has no children.
--
-- 100,000 contents. Content n belongs to category number ((n - 1) % 100) + 1 in the fixed
-- shuffle below, so every page mixes all three levels. Every 1000th content has no category.

create table category (
    id integer not null primary key,
    parent_id integer references category (id) on update cascade,
    name text not null,
    unique (parent_id, name)
);

create table content (
    id integer not null primary key,
    category_id integer references category (id) on update cascade,
    content text not null
);

create index content_category_id on content (category_id);

insert into category (id, parent_id, name) values
    (1, null, 'Politics'),
        (11, 1, 'Elections'),
            (111, 11, 'US Elections'),
            (112, 11, 'EU Elections'),
            (113, 11, 'Local Elections'),
        (12, 1, 'Policy'),
            (121, 12, 'Healthcare Policy'),
            (122, 12, 'Tax Policy'),
        (13, 1, 'Diplomacy'),
            (131, 13, 'Trade Agreements'),
    (2, null, 'Technology'),
        (21, 2, 'Artificial Intelligence'),
            (211, 21, 'Large Language Models'),
            (212, 21, 'Computer Vision'),
            (213, 21, 'Robotics'),
        (22, 2, 'Hardware'),
            (221, 22, 'Chips'),
            (222, 22, 'Smartphones'),
        (23, 2, 'Software'),
            (231, 23, 'Open Source'),
            (232, 23, 'Cloud Computing'),
    (3, null, 'Sports'),
        (31, 3, 'Football'),
            (311, 31, 'Premier League'),
            (312, 31, 'Champions League'),
            (313, 31, 'La Liga'),
        (32, 3, 'Basketball'),
            (321, 32, 'NBA'),
            (322, 32, 'EuroLeague'),
        (33, 3, 'Tennis'),
            (331, 33, 'Grand Slams'),
    (4, null, 'Business'),
        (41, 4, 'Markets'),
            (411, 41, 'Stocks'),
            (412, 41, 'Commodities'),
            (413, 41, 'Crypto'),
        (42, 4, 'Startups'),
            (421, 42, 'Funding'),
            (422, 42, 'Acquisitions'),
        (43, 4, 'Economy'),
            (431, 43, 'Inflation'),
            (432, 43, 'Employment'),
    (5, null, 'Entertainment'),
        (51, 5, 'Movies'),
            (511, 51, 'Box Office'),
            (512, 51, 'Film Festivals'),
            (513, 51, 'Animation'),
        (52, 5, 'Music'),
            (521, 52, 'Concerts'),
            (522, 52, 'Albums'),
        (53, 5, 'Television'),
    (6, null, 'Science'),
        (61, 6, 'Space'),
            (611, 61, 'Mars Missions'),
            (612, 61, 'Telescopes'),
        (62, 6, 'Climate'),
            (621, 62, 'Extreme Weather'),
            (622, 62, 'Renewable Energy'),
        (63, 6, 'Biology'),
            (631, 63, 'Genetics'),
            (632, 63, 'Neuroscience'),
    (7, null, 'Health'),
        (71, 7, 'Fitness'),
            (711, 71, 'Running'),
            (712, 71, 'Strength Training'),
        (72, 7, 'Nutrition'),
            (721, 72, 'Diets'),
            (722, 72, 'Supplements'),
        (73, 7, 'Medicine'),
            (731, 73, 'Vaccines'),
            (732, 73, 'Mental Health'),
    (8, null, 'Travel'),
        (81, 8, 'Destinations'),
            (811, 81, 'Asia'),
            (812, 81, 'Europe'),
            (813, 81, 'Americas'),
        (82, 8, 'Airlines'),
            (821, 82, 'Airports'),
        (83, 8, 'Hotels'),
            (831, 83, 'Budget Stays'),
            (832, 83, 'Luxury Resorts'),
    (9, null, 'Education'),
        (91, 9, 'Universities'),
            (911, 91, 'Admissions'),
            (912, 91, 'Research Funding'),
        (92, 9, 'Schools'),
            (921, 92, 'Curriculum'),
            (922, 92, 'Teachers'),
        (93, 9, 'Online Learning'),
            (931, 93, 'MOOCs'),
            (932, 93, 'Language Apps'),
    (10, null, 'Lifestyle'),
        (101, 10, 'Food & Drink'),
            (1011, 101, 'Recipes'),
            (1012, 101, 'Restaurants'),
        (102, 10, 'Fashion'),
            (1021, 102, 'Street Style'),
        (103, 10, 'Home & Garden'),
            (1031, 103, 'Interior Design'),
            (1032, 103, 'Gardening');

-- The fixed shuffle: category number 1..100, ordered by a multiplicative hash of the id.
create temp table category_slot as
select row_number() over (order by (id * 7919) % 10007, id) as slot, id, name
from category;

create temp table headline (k integer primary key, prefix text not null);
insert into headline (k, prefix) values
    (0, 'Breaking news:'),
    (1, 'Latest report:'),
    (2, 'Analysis:'),
    (3, 'Opinion:'),
    (4, 'Explainer:'),
    (5, 'Interview:'),
    (6, 'Live updates:');

insert into content (id, category_id, content)
select n.id,
       case when n.id % 1000 = 0 then null else s.id end,
       case when n.id % 1000 = 0 then 'Uncategorized note ' || n.id
            else h.prefix || ' ' || s.name || ' #' || n.id end
from generate_series(1, 100000) as n(id)
join category_slot s on s.slot = (n.id - 1) % 100 + 1
join headline h on h.k = n.id % 7;

vacuum analyze category;
vacuum analyze content;
