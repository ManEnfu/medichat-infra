DROP DATABASE IF EXISTS medichat_db;
CREATE DATABASE medichat_db;

\c medichat_db;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "unaccent";

CREATE OR REPLACE FUNCTION slugify("value" TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN regexp_replace(
           regexp_replace(
             lower(unaccent("value")),
             '[^a-z0-9\\-_]+', '-', 'gi'
           ),
           '(^-+|-+$)', '', 'g'
         );
END
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

CREATE TABLE accounts(
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    email_verified BOOLEAN NOT NULL,
    name VARCHAR NOT NULL,
    photo_url VARCHAR NOT NULL,
    role VARCHAR NOT NULL,
    account_type VARCHAR NOT NULL,
    hashed_password VARCHAR,
    profile_set BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);

CREATE TABLE refresh_tokens(
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id),

    token VARCHAR NOT NULL,
    client_ip VARCHAR NOT NULL,
    expired_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_account_id ON refresh_tokens(account_id);

CREATE TABLE reset_password_tokens(
    id BIGSERIAL PRIMARY KEY,

    account_id BIGINT NOT NULL REFERENCES accounts(id),

    token VARCHAR NOT NULL,
    expired_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);
CREATE INDEX idx_reset_password_tokens_token ON reset_password_tokens(token);
CREATE INDEX idx_reset_password_tokens_account_id ON reset_password_tokens(account_id);

CREATE TABLE verify_email_tokens(
    id BIGSERIAL PRIMARY KEY,

    account_id BIGINT NOT NULL REFERENCES accounts(id),

    token VARCHAR NOT NULL,
    expired_at TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);
CREATE INDEX idx_verify_email_tokens_token ON verify_email_tokens(token);
CREATE INDEX idx_verify_email_tokens_account_id ON verify_email_tokens(account_id);

create table admins (
    id BIGSERIAL PRIMARY KEY,

    account_id BIGINT not null,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
   
    foreign key (account_id) references accounts(id)
);

create table pharmacy_managers (
    id BIGSERIAL PRIMARY KEY,

    account_id BIGINT not null,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
   
    foreign key (account_id) references accounts(id)
);

create table users (
    id BIGSERIAL PRIMARY KEY,

    account_id BIGINT not null,
    date_of_birth DATE not null,
    main_location_id BIGINT NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
   
    foreign key (account_id) references accounts(id)
);

create table user_locations (
    id BIGSERIAL PRIMARY KEY,    
    user_id BIGINT not null,
    
    alias VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    coordinate GEOGRAPHY(POINT) NOT NULL,
    is_active boolean NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
   
    foreign key (user_id) references users(id)
);

create table specializations (
    id BIGSERIAL PRIMARY KEY,
    
    name VARCHAR NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);

create table doctors (
    id BIGSERIAL PRIMARY KEY,
    account_id BIGINT not null,
    specialization_id BIGINT not null,
    
    str VARCHAR NOT NULL,
    work_location VARCHAR NOT NULL,
    gender VARCHAR NOT NULL,
    phone_number VARCHAR NOT NULL,    
    is_active boolean NOT NULL,    
    start_work_date DATE not null,
    price int not null,
    certificate_url VARCHAR NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
   
    foreign key (account_id) references accounts(id),
    foreign key (specialization_id) references specializations(id)
);

create table ratings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT not null,
    doctor_id BIGINT not null,

    name VARCHAR NOT NULL,
    is_liked boolean NOT NULL,    

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    
    foreign key (user_id) references users(id),
    foreign key (doctor_id) references doctors(id)
);

create table chat_rooms (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT not null,
    doctor_id BIGINT not null,
    end_at Timestamp,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    
    foreign key (user_id) references users(id),
    foreign key (doctor_id) references doctors(id)
);

create table chat_items (
    id BIGSERIAL PRIMARY KEY,
    chat_room_id BIGINT not null,
    type VARCHAR NOT NULL,
    message TEXT NOT NULL,
    file TEXT NOT NULL,
    user_id BIGINT not null,
    user_name VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    foreign key (chat_room_id) references chat_rooms(id),
    foreign key (user_id) references accounts(id)
);

create table pharmacies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    address TEXT NOT NULL,
    coordinate GEOGRAPHY(POINT) NOT NULL,
    pharmacist_name VARCHAR NOT NULL,
    pharmacist_license VARCHAR NOT NULL,
    pharmacist_phone VARCHAR NOT NULL,
    slug VARCHAR NOT NULL,

    manager_id BIGINT not null,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    
    foreign key (manager_id) references pharmacy_managers(id)
);

CREATE INDEX ON pharmacies USING gist(coordinate);

CREATE OR REPLACE FUNCTION public.set_slug_from_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    counter INTEGER := 1;
BEGIN
    base_slug := slugify(NEW.name);
    final_slug := base_slug;

    LOOP
        IF EXISTS (SELECT 1 FROM "pharmacies" WHERE slug = final_slug AND id != COALESCE(NEW.id, 0)) THEN
            final_slug := base_slug || '-' || counter;
            counter := counter + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    NEW.slug := final_slug;
    RETURN NEW;
END
$$;

create table pharmacy_operations (
    id BIGSERIAL PRIMARY KEY,
    pharmacy_id BIGINT NOT NULL,
    
    day VARCHAR NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    
    foreign key (pharmacy_id) references pharmacies(id)
);

create table shipment_methods (
    id BIGSERIAL PRIMARY KEY,
    
    name VARCHAR NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);

create table pharmacy_shipment_methods (
    id BIGSERIAL PRIMARY KEY,
    
    pharmacy_id BIGINT NOT NULL,
    shipment_method_id BIGINT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (pharmacy_id) references pharmacies(id),
    foreign key (shipment_method_id) references shipment_methods(id)
);

CREATE SEQUENCE invoice_number_seq
    START 1
    INCREMENT 1
    MINVALUE 1;


create table payments(
    id BIGSERIAL PRIMARY KEY,
    invoice_number VARCHAR NOT NULL UNIQUE
        DEFAULT 'INV-' || now()::date || '-' || lpad((nextval('invoice_number_seq') % 1000000000)::text, 9, '0'),
    user_id BIGINT NOT NULL,

    file_url varchar,
    is_confirmed boolean NOT NULL,
    amount INT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (user_id) references users(id)
);

create table orders(
    id BIGSERIAL PRIMARY KEY,
    
    user_id BIGINT NOT NULL,
    pharmacy_id BIGINT NOT NULL,
    payment_id BIGINT NOT NULL,
    shipment_method_id BIGINT NOT NULL,

    address VARCHAR NOT NULL,
    coordinate GEOGRAPHY NOT NULL,

    n_items INTEGER NOT NULL,
    subtotal INTEGER NOT NULL,
    shipment_fee INTEGER NOT NULL,
    total INTEGER NOT NULL,

    status VARCHAR NOT NULL,
    ordered_at Timestamp NOT NULL,
    finished_at Timestamp, 
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (user_id) references users(id),
    foreign key (pharmacy_id) references pharmacies(id),
    foreign key (payment_id) references payments(id),
    foreign key (shipment_method_id) references shipment_methods(id)
);

create table order_shipment_methods (
    id BIGSERIAL PRIMARY KEY,
    
    order_id BIGINT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (order_id) references orders(id)
);

create table categories(
    id BIGSERIAL PRIMARY KEY,
    
    parent_id BIGINT,
    name varchar NOT NULL,

    slug VARCHAR NOT NULL,
    photo_url VARCHAR,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (parent_id) references categories(id)
);

create table product_details(
    id BIGSERIAL PRIMARY KEY,
    
    generic_name varchar NOT NULL,
    content varchar NOT NULL,
    composition varchar NOT NULL,
    manufacturer varchar NOT NULL,
    description varchar NOT NULL,
    product_classification varchar NOT NULL,
    product_form varchar NOT NULL,
    unit_in_pack varchar NOT NULL,
    selling_unit varchar NOT NULL,
    weight int NOT NULL,
    height int NOT NULL,
    length int NOT NULL,
    width int NOT NULL,
        
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP

);

CREATE OR REPLACE FUNCTION public.set_slug_from_product_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    counter INTEGER := 1;
BEGIN
    base_slug := slugify(NEW.name);
    final_slug := base_slug;
        LOOP
        IF EXISTS (SELECT 1 FROM "products" WHERE slug = final_slug AND id != COALESCE(NEW.id, 0)) THEN
            final_slug := base_slug || '-' || counter;
            counter := counter + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    NEW.slug := final_slug;
    RETURN NEW;
END
$$;

create table products(
    id BIGSERIAL PRIMARY KEY,
    
    category_id BIGINT NOT NULL,
    product_detail_id BIGINT NOT NULL,

    name varchar NOT NULL,
    picture varchar NOT NULL,
    is_active boolean NOT NULL,
    slug varchar NOT NULL,

    keyword varchar NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (category_id) references categories(id),
    foreign key (product_detail_id) references product_details(id)
);

create table stocks(
    id BIGSERIAL PRIMARY KEY,
    
    product_id BIGINT NOT NULL,
    pharmacy_id BIGINT NOT NULL,

    stock int NOT NULL,
    price int NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (product_id) references products(id),
    foreign key (pharmacy_id) references pharmacies(id)
);

create table order_items(
    id BIGSERIAL PRIMARY KEY,
    
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,

    price int NOT NULL,
    amount int NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (order_id) references orders(id),
    foreign key (product_id) references products(id)
);

create table stock_mutations(
    id BIGSERIAL PRIMARY KEY,
    
    source_id BIGINT NOT NULL,
    target_id BIGINT NOT NULL,

    method VARCHAR NOT NULL,
    status VARCHAR NOT NULL,
    amount int NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,

    foreign key (source_id) references stocks(id),
    foreign key (target_id) references stocks(id)
);


