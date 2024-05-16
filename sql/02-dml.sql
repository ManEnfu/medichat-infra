\c medichat_db;

INSERT INTO accounts(email, email_verified, name, photo_url, role, account_type, hashed_password, profile_set)
VALUES
('admin@medichat.com', true, 'Admin', 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png', 'admin', 'regular', '$2a$12$91dH2PX2G7LXj9zjwW8CNuXNwuPwhHGJZcddU0FzH0DIQetZNupzu', true),
('alice@medichat.com', true, 'Alice Johnson', 'https://www.eyeadorethreading.com/wp-content/uploads/2020/05/blank-profile.jpg', 'user', 'regular', '$2a$12$91dH2PX2G7LXj9zjwW8CNuXNwuPwhHGJZcddU0FzH0DIQetZNupzu', true),
('billy.bob@medichat.com', true, 'Billy-Bob Carter Jr', 'https://i.pinimg.com/originals/b5/d4/dc/b5d4dc75f88cb8f1cccf94b58108706d.png', 'doctor', 'regular', '$2a$12$91dH2PX2G7LXj9zjwW8CNuXNwuPwhHGJZcddU0FzH0DIQetZNupzu', true);

INSERT INTO admins(account_id)
VALUES
(1);

INSERT INTO users(account_id, date_of_birth, main_location_id)
VALUES
(2, '1992-08-23', 1);

INSERT INTO user_locations(user_id, alias, address, coordinate, is_active)
VALUES
(1, 'Home', 'Somewhere rd.', 'POINT(92.03 5.32)', true),
(1, 'Office', 'Lavender 123', 'POINT(93.13 7.10)', true);

INSERT INTO specializations(name)
VALUES
('Allergy and Immunology'),
('Anesthesiology'),
('Cardiology'),
('Dermatology'),
('Endocrinology'),
('Gastroenterology'),
('Gynecology'),
('Hematology'),
('Neurosurgery'),
('Neurology'),
('Oncology'),
('Ophthalmology'),
('Orthopedy'),
('Pediatrics'),
('Psychiatry'),
('Radiologist'),
('Rheumatology'),
('Urology');

INSERT INTO doctors(
    account_id, specialization_id, str, work_location, gender, 
    phone_number, is_active, start_work_date, price, certificate_url)
VALUES
(3, 1, '', 'Nowhere', 'male', '+1234567890', true, '1980-04-02', 75000, 'https://example.com');


INSERT INTO shipment_methods(name)
VALUES
('Official Instant'),
('Official Sameday'),
('JNE');
