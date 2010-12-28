

-- status can be 'start','complete','fail'

create table unit_test (
    build_number integer primary_key,
    date integer not null,
    status text not null,
    genome_hash text not null,
    ur_hash text not null,
    workflow_hash text not null
);


create table model_test (
    build_number integer primary_key,
    date integer not null,
    status text not null,
    unit_test_build_number integer not null,
);

-- foreign key(unit_test_build_number) references unit_test(build_number)
-- foreign keys not supported before sqlite 3.6.19

create table build (
    status text not null,
    model_test_id integer not null,
    foreign key(model_test_id) references model_test(build_number)
);



