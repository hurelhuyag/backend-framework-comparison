create table category (
    id integer not null primary key,
    parent_id int,
    name text not null,
    unique (parent_id, name),
    foreign key (parent_id) references category (id) on update cascade
);

create table content (
    id integer not null primary key,
    category_id int,
    content text not null,
    foreign key (category_id) references category(id) on update cascade
);
