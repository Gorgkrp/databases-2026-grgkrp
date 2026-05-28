DROP DATABASE IF EXISTS travel_agency_2025;
CREATE DATABASE travel_agency_2025;
USE travel_agency_2025;


CREATE TABLE travel_agency_2025_branch (
    br_code INT PRIMARY KEY,
    br_street VARCHAR(50),
    br_num INT,
    br_city VARCHAR(30),
    br_manager_AT CHAR(10) NOT NULL
);


CREATE TABLE travel_agency_2025_worker (
    wrk_AT CHAR(10) PRIMARY KEY,
    wrk_name VARCHAR(30),
    wrk_lname VARCHAR(30),
    wrk_email VARCHAR(100),
    wrk_salary DECIMAL(10,2),
    wrk_br_code INT,
    FOREIGN KEY (wrk_br_code) REFERENCES travel_agency_2025_branch(br_code)
);
CREATE TABLE travel_agency_2025_admin (
    adm_AT CHAR(10) PRIMARY KEY,
    adm_type ENUM('LOGISTICS','ADMINISTRATIVE','ACCOUNTING'),
    adm_diploma VARCHAR(200),
    FOREIGN KEY (adm_AT) REFERENCES travel_agency_2025_worker(wrk_AT)
);


ALTER TABLE travel_agency_2025_branch
ADD CONSTRAINT fk_branch_manager_admin
FOREIGN KEY (br_manager_AT) REFERENCES travel_agency_2025_admin(adm_AT);

CREATE TABLE travel_agency_2025_manages (
    mng_AT CHAR(10),
    mng_br_code INT,
    PRIMARY KEY (mng_AT, mng_br_code),
    FOREIGN KEY (mng_AT) REFERENCES travel_agency_2025_admin(adm_AT),
    FOREIGN KEY (mng_br_code) REFERENCES travel_agency_2025_branch(br_code)
);


CREATE TABLE travel_agency_2025_guide (
    gui_AT CHAR(10) PRIMARY KEY,
    gui_cv TEXT,
    FOREIGN KEY (gui_AT) REFERENCES travel_agency_2025_worker(wrk_AT)
);

CREATE TABLE travel_agency_2025_driver (
    drv_AT CHAR(10) PRIMARY KEY,
    drv_license ENUM('A','B','C','D'),
    drv_route ENUM('LOCAL','ABROAD'),
    drv_experience TINYINT,
    FOREIGN KEY (drv_AT) REFERENCES travel_agency_2025_worker(wrk_AT)
);


CREATE TABLE travel_agency_2025_language_ref (
    lang_code VARCHAR(5) PRIMARY KEY,
    lang_name VARCHAR(50)
);


CREATE TABLE travel_agency_2025_languages (
    lng_gui_AT CHAR(10),
    lng_language_code VARCHAR(5),
    PRIMARY KEY (lng_gui_AT, lng_language_code),
    FOREIGN KEY (lng_gui_AT) REFERENCES travel_agency_2025_guide(gui_AT),
    FOREIGN KEY (lng_language_code) REFERENCES travel_agency_2025_language_ref(lang_code)
);


CREATE TABLE travel_agency_2025_customer (
    cust_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_name VARCHAR(30),
    cust_lname VARCHAR(30),
    cust_email VARCHAR(100),
    cust_phone VARCHAR(15),
    cust_address TEXT,
    cust_birth_date DATE
);


CREATE TABLE travel_agency_2025_destination (
    dst_id INT AUTO_INCREMENT PRIMARY KEY,
    dst_name VARCHAR(100),
    dst_descr TEXT,
    dst_type ENUM('LOCAL','ABROAD'),
    dst_language_code VARCHAR(5),
    dst_location INT,
    FOREIGN KEY (dst_language_code) REFERENCES travel_agency_2025_language_ref(lang_code),
    FOREIGN KEY (dst_location) REFERENCES travel_agency_2025_destination(dst_id)
);


CREATE TABLE travel_agency_2025_trip (
    tr_id INT AUTO_INCREMENT PRIMARY KEY,
    tr_departure DATETIME,
    tr_return DATETIME,
    tr_maxseats TINYINT,
    tr_cost_adult DECIMAL(10,2),
    tr_cost_child DECIMAL(10,2),
    tr_status ENUM('PLANNED','CONFIRMED','ACTIVE','COMPLETED','CANCELLED'),
    tr_min_participants TINYINT,
    tr_br_code INT,
    tr_gui_AT CHAR(10),
    tr_drv_AT CHAR(10),
    FOREIGN KEY (tr_br_code) REFERENCES travel_agency_2025_branch(br_code),
    FOREIGN KEY (tr_gui_AT) REFERENCES travel_agency_2025_guide(gui_AT),
    FOREIGN KEY (tr_drv_AT) REFERENCES travel_agency_2025_driver(drv_AT)
);


CREATE TABLE travel_agency_2025_phones (
    ph_br_code INT,
    ph_number VARCHAR(15),
    PRIMARY KEY (ph_br_code, ph_number),
    FOREIGN KEY (ph_br_code) REFERENCES travel_agency_2025_branch(br_code)
);

CREATE TABLE travel_agency_2025_travel_to (
    to_tr_id INT,
    to_dst_id INT,
    to_arrival DATETIME,
    to_departure DATETIME,
    to_sequence TINYINT,
    PRIMARY KEY (to_tr_id, to_dst_id),
    FOREIGN KEY (to_tr_id) REFERENCES travel_agency_2025_trip(tr_id),
    FOREIGN KEY (to_dst_id) REFERENCES travel_agency_2025_destination(dst_id)
);


CREATE TABLE travel_agency_2025_event (
    ev_tr_id INT,
    ev_start DATETIME,
    ev_end DATETIME,
    ev_descr TEXT,
    PRIMARY KEY (ev_tr_id, ev_start),
    FOREIGN KEY (ev_tr_id) REFERENCES travel_agency_2025_trip(tr_id)
);


CREATE TABLE travel_agency_2025_reservation (
    res_tr_id INT,
    res_seatnum TINYINT,
    res_cust_id INT,
    res_status ENUM('PENDING','CONFIRMED','PAID','CANCELLED'),
    res_total_cost DECIMAL(10,2),
    PRIMARY KEY (res_tr_id, res_seatnum),
    FOREIGN KEY (res_tr_id) REFERENCES travel_agency_2025_trip(tr_id),
    FOREIGN KEY (res_cust_id) REFERENCES travel_agency_2025_customer(cust_id)
);

CREATE TABLE travel_agency_2025_vehicle (
    veh_id INT AUTO_INCREMENT PRIMARY KEY,
    veh_br_code INT NOT NULL,
    veh_brand VARCHAR(50) NOT NULL,
    veh_model VARCHAR(50) NOT NULL,
    veh_plate VARCHAR(15) NOT NULL UNIQUE,
    veh_seats TINYINT NOT NULL,
    veh_type ENUM('BUS','MINIBUS','VAN','CAR') NOT NULL,
    veh_status ENUM('AVAILABLE','IN_USE','MAINTENANCE') NOT NULL DEFAULT 'AVAILABLE',
    veh_total_km INT NOT NULL DEFAULT 0,
    FOREIGN KEY (veh_br_code) REFERENCES travel_agency_2025_branch(br_code),
    CHECK (veh_seats > 0),
    CHECK (
        (veh_type='CAR' AND veh_seats <= 5) OR
        (veh_type='VAN' AND veh_seats BETWEEN 6 AND 9) OR
        (veh_type='MINIBUS' AND veh_seats BETWEEN 10 AND 20) OR
        (veh_type='BUS' AND veh_seats > 20)
    )
);

DROP TABLE IF EXISTS travel_agency_2025_trip_vehicle;
CREATE TABLE travel_agency_2025_trip_vehicle (
    tv_tr_id INT PRIMARY KEY,
    tv_veh_id INT NOT NULL,
    tv_start_km INT NOT NULL,
    tv_end_km INT NULL,
    tv_assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tv_tr_id) REFERENCES travel_agency_2025_trip(tr_id),
    FOREIGN KEY (tv_veh_id) REFERENCES travel_agency_2025_vehicle(veh_id),
    CHECK (tv_start_km >= 0),
    CHECK (tv_end_km IS NULL OR tv_end_km >= 0),
    INDEX idx_tv_vehicle (tv_veh_id)
);

CREATE TABLE travel_agency_2025_accommodation (
    acc_id INT AUTO_INCREMENT PRIMARY KEY,
    acc_dst_id INT NOT NULL,
    acc_name VARCHAR(120) NOT NULL,
    acc_type ENUM('HOTEL','GUESTHOUSE','RESORT','APARTMENTS','ROOMS') NOT NULL,
    acc_stars TINYINT NULL,
    acc_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    acc_status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    acc_street VARCHAR(80) NOT NULL,
    acc_num VARCHAR(10) NOT NULL,
    acc_city VARCHAR(40) NOT NULL,
    acc_zip VARCHAR(10) NOT NULL,
    acc_phone VARCHAR(20) NOT NULL,
    acc_email VARCHAR(120) NOT NULL,
    acc_total_rooms INT NOT NULL,
    acc_price_per_room_night DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (acc_dst_id) REFERENCES travel_agency_2025_destination(dst_id),
    CHECK (acc_rating BETWEEN 0.00 AND 5.00),
    CHECK (acc_total_rooms > 0),
    CHECK (acc_price_per_room_night >= 0),
    CHECK (
        (acc_type IN ('HOTEL','RESORT') AND acc_stars BETWEEN 1 AND 5) OR
        (acc_type NOT IN ('HOTEL','RESORT') AND acc_stars IS NULL)
    )
);

CREATE TABLE travel_agency_2025_accommodation_facility (
    af_acc_id INT NOT NULL,
    af_facility ENUM('WIFI','RESTAURANT_BAR','AIRCON','ACCESSIBLE') NOT NULL,
    PRIMARY KEY (af_acc_id, af_facility),
    FOREIGN KEY (af_acc_id) REFERENCES travel_agency_2025_accommodation(acc_id)
);

CREATE TABLE travel_agency_2025_stay_booking (
    sb_id INT AUTO_INCREMENT PRIMARY KEY,
    sb_tr_id INT NOT NULL,
    sb_dst_id INT NOT NULL,
    sb_acc_id INT NOT NULL,
    sb_checkin DATE NOT NULL,
    sb_checkout DATE NOT NULL,
    sb_rooms INT NOT NULL,
    sb_nights INT NULL,
    sb_total_cost DECIMAL(12,2) NULL,
    FOREIGN KEY (sb_tr_id) REFERENCES travel_agency_2025_trip(tr_id),
    FOREIGN KEY (sb_dst_id) REFERENCES travel_agency_2025_destination(dst_id),
    FOREIGN KEY (sb_acc_id) REFERENCES travel_agency_2025_accommodation(acc_id),
    CHECK (sb_checkout > sb_checkin),
    CHECK (sb_rooms > 0),
    INDEX idx_sb_acc_dates (sb_acc_id, sb_checkin, sb_checkout)
);

CREATE TABLE travel_agency_2025_trip_history (
    th_tr_id INT NOT NULL,
    th_departure DATE NOT NULL,
    th_return DATE NOT NULL,
    th_destinations_count INT NOT NULL,
    th_participants_count INT NOT NULL,
    th_total_revenue DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (th_tr_id),
    CHECK (th_return >= th_departure),
    CHECK (th_destinations_count >= 0),
    CHECK (th_participants_count >= 0),
    CHECK (th_total_revenue >= 0)
);
CREATE INDEX idx_th_departure
ON travel_agency_2025_trip_history (th_departure);

CREATE INDEX idx_th_destinations_departure
ON travel_agency_2025_trip_history (th_destinations_count, th_departure);	

CREATE TABLE travel_agency_2025_dba (
    dba_username VARCHAR(200) PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE travel_agency_2025_dba_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    log_dt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    log_username VARCHAR(200) NOT NULL,
    log_action ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    log_table_name VARCHAR(64) NOT NULL,
    log_pk VARCHAR(200) NULL
);



