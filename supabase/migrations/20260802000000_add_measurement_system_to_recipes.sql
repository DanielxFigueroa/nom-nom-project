alter table recipes
  add column measurement_system text not null default 'imperial';
