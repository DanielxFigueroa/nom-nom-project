alter table recipes add column servings integer not null default 4;
alter table ingredients add column quantity_value numeric;
