SET FOREIGN_KEY_CHECKS = 0;

INSERT INTO travel_agency_2025_language_ref (lang_code, lang_name) VALUES
('EN','English'),
('EL','Greek'),
('FR','French'),
('DE','German'),
('ES','Spanish');

INSERT INTO travel_agency_2025_branch (br_code, br_street, br_num, br_city, br_manager_AT) VALUES
(1,'Main',10,'Athens','0000000001'),
(2,'Sea',22,'Thessaloniki','0000000002'),
(3,'Hill',5,'Patras','0000000003');

INSERT INTO travel_agency_2025_worker (wrk_AT, wrk_name, wrk_lname, wrk_email, wrk_salary, wrk_br_code) VALUES
('0000000001','Nikos','Admin','nikos.admin@agency.gr',1800.00,1),
('0000000002','Maria','Admin','maria.admin@agency.gr',1750.00,2),
('0000000003','Giorgos','Admin','giorgos.admin@agency.gr',1700.00,3),
('0000000010','Eleni','Guide','eleni.guide@agency.gr',1400.00,1),
('0000000011','Petros','Guide','petros.guide@agency.gr',1450.00,2),
('0000000020','Kostas','Driver','kostas.driver@agency.gr',1500.00,1),
('0000000021','Anna','Driver','anna.driver@agency.gr',1550.00,2);

INSERT INTO travel_agency_2025_admin (adm_AT, adm_type, adm_diploma) VALUES
('0000000001','ADMINISTRATIVE','BA Business'),
('0000000002','LOGISTICS','BA Logistics'),
('0000000003','ACCOUNTING','BA Accounting');

INSERT INTO travel_agency_2025_manages (mng_AT, mng_br_code) VALUES
('0000000001',1),
('0000000001',2),
('0000000002',2),
('0000000003',3);

INSERT INTO travel_agency_2025_guide (gui_AT, gui_cv) VALUES
('0000000010','Experienced guide, city tours and museums.'),
('0000000011','Outdoor guide, hiking and local culture.');

INSERT INTO travel_agency_2025_driver (drv_AT, drv_license, drv_route, drv_experience) VALUES
('0000000020','D','LOCAL',8),
('0000000021','C','ABROAD',6);

INSERT INTO travel_agency_2025_languages (lng_gui_AT, lng_language_code) VALUES
('0000000010','EL'),
('0000000010','EN'),
('0000000011','EN'),
('0000000011','DE');

INSERT INTO travel_agency_2025_destination (dst_name, dst_descr, dst_type, dst_language_code, dst_location) VALUES
('Greece','Country','LOCAL','EL',NULL),
('Athens','Capital city','LOCAL','EL',1),
('Thessaloniki','Northern city','LOCAL','EL',1),
('Germany','Country','ABROAD','DE',NULL),
('Berlin','Capital city','ABROAD','DE',4);

INSERT INTO travel_agency_2025_customer (cust_name, cust_lname, cust_email, cust_phone, cust_address, cust_birth_date) VALUES
('John','Doe','john.doe@mail.com','6900000001','Athens, GR','1995-05-10'),
('Jane','Doe','jane.doe@mail.com','6900000002','Athens, GR','1997-02-21'),
('Alex','Smith','alex.smith@mail.com','6900000003','Berlin, DE','1992-11-03');

INSERT INTO travel_agency_2025_trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_min_participants, tr_br_code, tr_gui_AT, tr_drv_AT) VALUES
('2026-01-10 08:00:00','2026-01-12 20:00:00',20,200.00,120.00,'CONFIRMED',5,1,'0000000010','0000000020'),
('2026-02-05 07:00:00','2026-02-10 21:00:00',50,550.00,350.00,'PLANNED',10,2,'0000000011','0000000021');

INSERT INTO travel_agency_2025_travel_to (to_tr_id, to_dst_id, to_arrival, to_departure, to_sequence) VALUES
(1,2,'2026-01-10 10:00:00','2026-01-11 18:00:00',1),
(1,3,'2026-01-11 20:00:00','2026-01-12 18:00:00',2),
(2,5,'2026-02-05 12:00:00','2026-02-10 18:00:00',1);

INSERT INTO travel_agency_2025_event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
(1,'2026-01-10 12:00:00','2026-01-10 14:00:00','Museum visit'),
(1,'2026-01-11 11:00:00','2026-01-11 13:00:00','Food tasting');

INSERT INTO travel_agency_2025_reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost) VALUES
(1,1,1,'CONFIRMED',200.00),
(1,2,2,'PAID',200.00),
(2,1,3,'PENDING',550.00);

INSERT INTO travel_agency_2025_phones (ph_br_code, ph_number) VALUES
(1,'2100000001'),
(2,'2310000002'),
(3,'2610000003');

INSERT INTO travel_agency_2025_vehicle (veh_br_code, veh_brand, veh_model, veh_plate, veh_seats, veh_type, veh_status, veh_total_km) VALUES
(1,'Mercedes','Sprinter','ΙΒΑ-1234',16,'MINIBUS','AVAILABLE',120000),
(2,'Setra','S 515','ΝΚΗ-5678',52,'BUS','AVAILABLE',250000),
(2,'Toyota','Corolla','ΖΖΖ-9999',5,'CAR','MAINTENANCE',80000);

INSERT INTO travel_agency_2025_trip_vehicle (tv_tr_id, tv_veh_id, tv_start_km, tv_end_km, tv_assigned_at) VALUES
(1,1,120050,NULL,'2026-01-09 18:00:00');

INSERT INTO travel_agency_2025_accommodation (acc_dst_id, acc_name, acc_type, acc_stars, acc_rating, acc_status, acc_street, acc_num, acc_city, acc_zip, acc_phone, acc_email, acc_total_rooms, acc_price_per_room_night) VALUES
(2,'Acropolis Hotel','HOTEL',4,4.30,'ACTIVE','Dionysiou',12,'Athens','11742','2101111111','info@acropolis-hotel.gr',80,95.00),
(2,'Plaka Rooms','ROOMS',NULL,4.10,'ACTIVE','Adrianou',8,'Athens','10558','2102222222','contact@plaka-rooms.gr',20,60.00),
(3,'Thess City Hotel','HOTEL',3,4.00,'ACTIVE','Egnatia',45,'Thessaloniki','54630','2310333333','hello@thesscity.gr',60,75.00),
(5,'Berlin Central','HOTEL',4,4.50,'ACTIVE','Alexanderplatz',1,'Berlin','10178','030444444','stay@berlincentral.de',120,130.00);

INSERT INTO travel_agency_2025_accommodation_facility (af_acc_id, af_facility) VALUES
(1,'WIFI'),
(1,'AIRCON'),
(1,'RESTAURANT_BAR'),
(2,'WIFI'),
(3,'WIFI'),
(3,'ACCESSIBLE'),
(4,'WIFI'),
(4,'AIRCON'),
(4,'ACCESSIBLE');

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO travel_agency_2025_trip_history (th_tr_id, th_departure, th_return, th_destinations_count, th_participants_count, th_total_revenue)
SELECT
  n + 1 AS th_tr_id,
  DATE_ADD('2018-01-01', INTERVAL (n % 2190) DAY) AS th_departure,
  DATE_ADD(DATE_ADD('2018-01-01', INTERVAL (n % 2190) DAY), INTERVAL (1 + (n % 12)) DAY) AS th_return,
  1 + (n % 6) AS th_destinations_count,
  5 + (n % 45) AS th_participants_count,
  (200 + (n % 800)) * (5 + (n % 45)) AS th_total_revenue
FROM (
  SELECT
    (a.d
     + 10*b.d
     + 100*c.d
     + 1000*d.d
     + 10000*e.d) AS n
  FROM (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
  CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
  CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
  CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
  CROSS JOIN (SELECT 0 d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
) nums
WHERE n < 90000;

INSERT INTO travel_agency_2025_worker (wrk_AT, wrk_name, wrk_lname, wrk_email, wrk_salary, wrk_br_code) VALUES
('0000000004','Dimitris','Admin','dimitris.admin@agency.gr',1720.00,1),
('0000000005','Sofia','Admin','sofia.admin@agency.gr',1760.00,2),
('0000000012','Irene','Guide','irene.guide@agency.gr',1420.00,1),
('0000000013','Manos','Guide','manos.guide@agency.gr',1410.00,3),
('0000000022','Vasilis','Driver','vasilis.driver@agency.gr',1520.00,1),
('0000000023','Nadia','Driver','nadia.driver@agency.gr',1530.00,3);

INSERT INTO travel_agency_2025_admin (adm_AT, adm_type, adm_diploma) VALUES
('0000000004','LOGISTICS','BA Logistics'),
('0000000005','ADMINISTRATIVE','BA Business');

INSERT INTO travel_agency_2025_guide (gui_AT, gui_cv) VALUES
('0000000012','Guide for city tours and culture.'),
('0000000013','Guide for outdoor activities and history.');

INSERT INTO travel_agency_2025_driver (drv_AT, drv_license, drv_route, drv_experience) VALUES
('0000000022','D','LOCAL',5),
('0000000023','C','ABROAD',7);

INSERT INTO travel_agency_2025_languages (lng_gui_AT, lng_language_code) VALUES
('0000000012','EN'),
('0000000012','FR'),
('0000000013','EL'),
('0000000013','ES');

INSERT INTO travel_agency_2025_customer (cust_name, cust_lname, cust_email, cust_phone, cust_address, cust_birth_date) VALUES
('Chris','Brown','chris.brown@mail.com','6900000004','Patras, GR','1990-01-12'),
('Maria','Pappas','maria.pappas@mail.com','6900000005','Thessaloniki, GR','1999-03-14'),
('Giorgos','Klein','giorgos.klein@mail.com','6900000006','Berlin, DE','1988-07-22'),
('Ema','Lopez','ema.lopez@mail.com','6900000007','Athens, GR','2000-09-09'),
('Lena','Meyer','lena.meyer@mail.com','6900000008','Berlin, DE','1996-12-01'),
('Antonis','Nikou','antonis.nikou@mail.com','6900000009','Athens, GR','1993-04-18'),
('Katerina','Iliou','katerina.iliou@mail.com','6900000010','Patras, GR','1994-06-30');

INSERT INTO travel_agency_2025_phones (ph_br_code, ph_number) VALUES
(1,'2100000004'),
(2,'2310000005');

INSERT INTO travel_agency_2025_trip (tr_departure, tr_return, tr_maxseats, tr_cost_adult, tr_cost_child, tr_status, tr_min_participants, tr_br_code, tr_gui_AT, tr_drv_AT) VALUES
('2026-03-01 08:00:00','2026-03-03 20:00:00',16,180.00,110.00,'PLANNED',5,1,'0000000012','0000000022'),
('2026-03-15 07:30:00','2026-03-18 21:00:00',52,480.00,300.00,'CONFIRMED',12,2,'0000000011','0000000021'),
('2026-04-02 09:00:00','2026-04-05 22:00:00',20,260.00,160.00,'PLANNED',6,3,'0000000013','0000000023'),
('2026-04-20 06:00:00','2026-04-26 23:00:00',52,620.00,390.00,'PLANNED',15,2,'0000000010','0000000021'),
('2026-05-10 10:00:00','2026-05-12 20:00:00',16,210.00,130.00,'CONFIRMED',5,1,'0000000012','0000000020');

INSERT INTO travel_agency_2025_travel_to (to_tr_id, to_dst_id, to_arrival, to_departure, to_sequence) VALUES
(3,2,'2026-03-01 10:00:00','2026-03-02 18:00:00',1),
(3,3,'2026-03-02 20:00:00','2026-03-03 18:00:00',2),
(4,5,'2026-03-15 12:00:00','2026-03-18 18:00:00',1),
(5,2,'2026-04-02 12:00:00','2026-04-04 18:00:00',1);

INSERT INTO travel_agency_2025_event (ev_tr_id, ev_start, ev_end, ev_descr) VALUES
(2,'2026-02-06 10:00:00','2026-02-06 12:00:00','City walk'),
(2,'2026-02-07 11:00:00','2026-02-07 13:00:00','Local market'),
(3,'2026-03-01 12:00:00','2026-03-01 14:00:00','Museum visit'),
(3,'2026-03-02 11:00:00','2026-03-02 13:00:00','Food tasting'),
(4,'2026-03-16 10:30:00','2026-03-16 12:00:00','Historic tour'),
(4,'2026-03-17 15:00:00','2026-03-17 17:00:00','Cultural event'),
(5,'2026-04-03 10:00:00','2026-04-03 12:00:00','Acropolis visit'),
(5,'2026-04-04 16:00:00','2026-04-04 18:00:00','City bus tour');

INSERT INTO travel_agency_2025_reservation (res_tr_id, res_seatnum, res_cust_id, res_status, res_total_cost) VALUES
(1,3,3,'CONFIRMED',200.00),
(1,4,4,'PAID',200.00),
(1,5,5,'PENDING',200.00),
(2,3,6,'CONFIRMED',550.00),
(2,4,7,'PAID',550.00),
(2,5,8,'PENDING',550.00),
(3,1,9,'CONFIRMED',180.00),
(3,2,10,'PAID',180.00),
(4,1,1,'PENDING',480.00);
