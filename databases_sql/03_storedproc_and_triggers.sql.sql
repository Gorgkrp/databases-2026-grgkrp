DROP PROCEDURE IF EXISTS sp_assign_vehicle_to_trip;
DROP PROCEDURE IF EXISTS sp_find_available_accommodations;
DROP PROCEDURE IF EXISTS sp_book_stays_for_trip;
DROP PROCEDURE IF EXISTS sp_history_revenue_between;
DROP PROCEDURE IF EXISTS sp_history_dates_by_destinations;

DROP TRIGGER IF EXISTS trg_accommodation_city_only_ins;
DROP TRIGGER IF EXISTS trg_accommodation_city_only_upd;

DROP TRIGGER IF EXISTS trg_stay_booking_calc;

DROP TRIGGER IF EXISTS trg_trip_vehicle_validate_endkm;
DROP TRIGGER IF EXISTS trg_trip_vehicle_close_trip;

DROP TRIGGER IF EXISTS trg_log_trip_ins;
DROP TRIGGER IF EXISTS trg_log_trip_upd;
DROP TRIGGER IF EXISTS trg_log_trip_del;

DROP TRIGGER IF EXISTS trg_log_reservation_ins;
DROP TRIGGER IF EXISTS trg_log_reservation_upd;
DROP TRIGGER IF EXISTS trg_log_reservation_del;

DROP TRIGGER IF EXISTS trg_log_customer_ins;
DROP TRIGGER IF EXISTS trg_log_customer_upd;
DROP TRIGGER IF EXISTS trg_log_customer_del;

DROP TRIGGER IF EXISTS trg_log_destination_ins;
DROP TRIGGER IF EXISTS trg_log_destination_upd;
DROP TRIGGER IF EXISTS trg_log_destination_del;

DROP TRIGGER IF EXISTS trg_log_vehicle_ins;
DROP TRIGGER IF EXISTS trg_log_vehicle_upd;
DROP TRIGGER IF EXISTS trg_log_vehicle_del;

DROP TRIGGER IF EXISTS trg_log_accommodation_ins;
DROP TRIGGER IF EXISTS trg_log_accommodation_upd;
DROP TRIGGER IF EXISTS trg_log_accommodation_del;

DROP TRIGGER IF EXISTS trg_log_stay_booking_ins;
DROP TRIGGER IF EXISTS trg_log_stay_booking_upd;
DROP TRIGGER IF EXISTS trg_log_stay_booking_del;

DELIMITER $$

CREATE TRIGGER trg_accommodation_city_only_ins
BEFORE INSERT ON travel_agency_2025_accommodation
FOR EACH ROW
BEGIN
  IF (SELECT dst_location
      FROM travel_agency_2025_destination
      WHERE dst_id = NEW.acc_dst_id) IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'FAIL: Accommodation must be linked to a city destination (not a country).';
  END IF;
END$$

CREATE TRIGGER trg_accommodation_city_only_upd
BEFORE UPDATE ON travel_agency_2025_accommodation
FOR EACH ROW
BEGIN
  IF NEW.acc_dst_id <> OLD.acc_dst_id THEN
    IF (SELECT dst_location
        FROM travel_agency_2025_destination
        WHERE dst_id = NEW.acc_dst_id) IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'FAIL: Accommodation must be linked to a city destination (not a country).';
    END IF;
  END IF;
END$$

CREATE PROCEDURE sp_assign_vehicle_to_trip (
    IN p_tr_id INT,
    IN p_veh_id INT,
    IN p_current_km INT
)
BEGIN
    DECLARE v_msg TEXT DEFAULT '';
    DECLARE v_ok INT DEFAULT 1;

    DECLARE v_trip_exists INT DEFAULT 0;
    DECLARE v_vehicle_exists INT DEFAULT 0;

    DECLARE v_tr_depart DATETIME;
    DECLARE v_tr_return DATETIME;
    DECLARE v_driver_AT CHAR(10);

    DECLARE v_veh_status VARCHAR(20);
    DECLARE v_veh_seats INT;
    DECLARE v_veh_total_km INT;

    DECLARE v_driver_licence CHAR(1);

    DECLARE v_needed_seats INT DEFAULT 0;
    DECLARE v_overlap_count INT DEFAULT 0;
    DECLARE v_already_assigned INT DEFAULT 0;

    IF p_tr_id IS NULL OR p_veh_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: p_tr_id and p_veh_id cannot be NULL.';
    END IF;

    IF p_current_km IS NULL OR p_current_km < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: p_current_km must be >= 0.';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_trip_exists
    FROM travel_agency_2025_trip
    WHERE tr_id = p_tr_id;

    IF v_trip_exists = 0 THEN
        SET v_ok = 0;
        SET v_msg = CONCAT(v_msg, 'FAIL: Trip not found.\n');
    ELSE
        SET v_msg = CONCAT(v_msg, 'OK: Trip found.\n');
        SELECT tr_departure, tr_return, tr_drv_AT
          INTO v_tr_depart, v_tr_return, v_driver_AT
        FROM travel_agency_2025_trip
        WHERE tr_id = p_tr_id;

        IF v_tr_depart IS NULL OR v_tr_return IS NULL THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Trip dates missing.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: Trip dates present.\n');
        END IF;

        IF v_tr_depart IS NOT NULL AND v_tr_return IS NOT NULL AND v_tr_return <= v_tr_depart THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Trip return must be after departure.\n');
        ELSEIF v_tr_depart IS NOT NULL AND v_tr_return IS NOT NULL THEN
            SET v_msg = CONCAT(v_msg, 'OK: Trip date order valid.\n');
        END IF;
    END IF;

    SELECT COUNT(*) INTO v_vehicle_exists
    FROM travel_agency_2025_vehicle
    WHERE veh_id = p_veh_id;

    IF v_vehicle_exists = 0 THEN
        SET v_ok = 0;
        SET v_msg = CONCAT(v_msg, 'FAIL: Vehicle not found.\n');
    ELSE
        SELECT veh_status, veh_seats, veh_total_km
          INTO v_veh_status, v_veh_seats, v_veh_total_km
        FROM travel_agency_2025_vehicle
        WHERE veh_id = p_veh_id
        FOR UPDATE;

        SET v_msg = CONCAT(v_msg, 'OK: Vehicle found (locked).\n');

        IF v_veh_status <> 'AVAILABLE' THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Vehicle status is not AVAILABLE.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: Vehicle is AVAILABLE.\n');
        END IF;

        IF p_current_km < v_veh_total_km THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Current KM less than vehicle total KM.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: Current KM is valid.\n');
        END IF;
    END IF;

    SELECT COUNT(*) INTO v_already_assigned
    FROM travel_agency_2025_trip_vehicle
    WHERE tv_tr_id = p_tr_id;

    IF v_already_assigned > 0 THEN
        SET v_ok = 0;
        SET v_msg = CONCAT(v_msg, 'FAIL: Trip already has an assigned vehicle.\n');
    ELSE
        SET v_msg = CONCAT(v_msg, 'OK: Trip has no assigned vehicle yet.\n');
    END IF;

    SELECT COUNT(*) INTO v_needed_seats
    FROM travel_agency_2025_reservation
    WHERE res_tr_id = p_tr_id
      AND res_status <> 'CANCELLED';

    IF v_vehicle_exists = 1 THEN
        IF v_veh_seats < v_needed_seats THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Not enough seats for non-cancelled reservations.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: Seats sufficient for reservations.\n');
        END IF;
    END IF;

    IF v_trip_exists = 1 THEN
        SELECT drv_license INTO v_driver_licence
        FROM travel_agency_2025_driver
        WHERE drv_AT = v_driver_AT;

        IF v_driver_licence IS NULL THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Trip driver not found in driver table.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: Driver exists.\n');

            IF v_vehicle_exists = 1 THEN
                IF v_veh_seats > 9 THEN
                    IF v_driver_licence NOT IN ('C','D') THEN
                        SET v_ok = 0;
                        SET v_msg = CONCAT(v_msg, 'FAIL: Licence must be C or D for vehicles with >9 seats.\n');
                    ELSE
                        SET v_msg = CONCAT(v_msg, 'OK: Licence valid for >9 seats.\n');
                    END IF;
                ELSE
                    IF v_driver_licence NOT IN ('B','C','D') THEN
                        SET v_ok = 0;
                        SET v_msg = CONCAT(v_msg, 'FAIL: Licence must be B/C/D for vehicles with <=9 seats.\n');
                    ELSE
                        SET v_msg = CONCAT(v_msg, 'OK: Licence valid for <=9 seats.\n');
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;

    IF v_trip_exists = 1 AND v_vehicle_exists = 1 AND v_tr_depart IS NOT NULL AND v_tr_return IS NOT NULL THEN
        SELECT COUNT(*) INTO v_overlap_count
        FROM travel_agency_2025_trip_vehicle tv
        JOIN travel_agency_2025_trip t2 ON t2.tr_id = tv.tv_tr_id
        WHERE tv.tv_veh_id = p_veh_id
          AND (t2.tr_departure < v_tr_return AND t2.tr_return > v_tr_depart);

        IF v_overlap_count > 0 THEN
            SET v_ok = 0;
            SET v_msg = CONCAT(v_msg, 'FAIL: Vehicle has time overlap with another trip.\n');
        ELSE
            SET v_msg = CONCAT(v_msg, 'OK: No time overlap for vehicle.\n');
        END IF;
    END IF;

    IF v_ok = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    ELSE
        INSERT INTO travel_agency_2025_trip_vehicle (tv_tr_id, tv_veh_id, tv_start_km)
        VALUES (p_tr_id, p_veh_id, p_current_km);

        UPDATE travel_agency_2025_vehicle
        SET veh_status = 'IN_USE'
        WHERE veh_id = p_veh_id;

        COMMIT;

        SET v_msg = CONCAT(v_msg, 'OK: Vehicle assigned and status set to IN_USE.\n');
        SELECT v_msg AS result_message;
    END IF;
END$$

CREATE PROCEDURE sp_find_available_accommodations (
    IN p_dst_id INT,
    IN p_arrival DATE,
    IN p_departure DATE,
    IN p_rooms INT,
    OUT p_first_acc_id INT
)
BEGIN
    DECLARE v_is_city INT DEFAULT 0;

    IF p_dst_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: destination id cannot be NULL.';
    END IF;

    IF p_departure <= p_arrival THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: departure must be after arrival.';
    END IF;

    IF p_rooms <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: required rooms must be > 0.';
    END IF;

    SELECT CASE WHEN dst_location IS NULL THEN 0 ELSE 1 END
      INTO v_is_city
    FROM travel_agency_2025_destination
    WHERE dst_id = p_dst_id;

    IF v_is_city = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: accommodation search applies only to city destinations.';
    END IF;

    SET p_first_acc_id = NULL;

    SELECT q.acc_id
      INTO p_first_acc_id
    FROM (
        SELECT
            a.acc_id,
            a.acc_price_per_room_night,
            a.acc_stars,
            a.acc_rating
        FROM travel_agency_2025_accommodation a
        LEFT JOIN (
            SELECT sb_acc_id,
                   SUM(sb_rooms) AS booked_rooms
            FROM travel_agency_2025_stay_booking
            WHERE NOT (sb_checkout <= p_arrival OR sb_checkin >= p_departure)
            GROUP BY sb_acc_id
        ) b ON b.sb_acc_id = a.acc_id
        WHERE a.acc_dst_id = p_dst_id
          AND a.acc_status = 'ACTIVE'
          AND (a.acc_total_rooms - IFNULL(b.booked_rooms, 0)) >= p_rooms
        ORDER BY a.acc_price_per_room_night ASC,
                 a.acc_stars DESC,
                 a.acc_rating DESC
        LIMIT 1
    ) q;

    SELECT
        a.acc_id,
        a.acc_name,
        a.acc_type,
        CONCAT(a.acc_street, ' ', a.acc_num, ', ', a.acc_city, ' ', a.acc_zip) AS acc_address,
        a.acc_phone,
        a.acc_stars,
        a.acc_rating,
        a.acc_price_per_room_night,
        IFNULL(f.facilities, '') AS facilities,
        (a.acc_total_rooms - IFNULL(b.booked_rooms, 0)) AS available_rooms
    FROM travel_agency_2025_accommodation a
    LEFT JOIN (
        SELECT sb_acc_id,
               SUM(sb_rooms) AS booked_rooms
        FROM travel_agency_2025_stay_booking
        WHERE NOT (sb_checkout <= p_arrival OR sb_checkin >= p_departure)
        GROUP BY sb_acc_id
    ) b ON b.sb_acc_id = a.acc_id
    LEFT JOIN (
        SELECT af_acc_id,
               GROUP_CONCAT(af_facility ORDER BY af_facility SEPARATOR ',') AS facilities
        FROM travel_agency_2025_accommodation_facility
        GROUP BY af_acc_id
    ) f ON f.af_acc_id = a.acc_id
    WHERE a.acc_dst_id = p_dst_id
      AND a.acc_status = 'ACTIVE'
      AND (a.acc_total_rooms - IFNULL(b.booked_rooms, 0)) >= p_rooms
    ORDER BY a.acc_price_per_room_night ASC,
             a.acc_stars DESC,
             a.acc_rating DESC;
END$$

CREATE PROCEDURE sp_book_stays_for_trip (
    IN p_tr_id INT,
    IN p_rooms INT
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_dst_id INT;
    DECLARE v_arr DATE;
    DECLARE v_dep DATE;
    DECLARE v_first_acc INT;
    DECLARE v_trip_exists INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT to_dst_id, DATE(to_arrival), DATE(to_departure)
        FROM travel_agency_2025_travel_to
        WHERE to_tr_id = p_tr_id
        ORDER BY to_sequence;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    IF p_rooms <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: rooms must be > 0.';
    END IF;

    SELECT COUNT(*) INTO v_trip_exists
    FROM travel_agency_2025_trip
    WHERE tr_id = p_tr_id;

    IF v_trip_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: Trip not found.';
    END IF;

    START TRANSACTION;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_dst_id, v_arr, v_dep;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        CALL sp_find_available_accommodations(v_dst_id, v_arr, v_dep, p_rooms, v_first_acc);

        IF v_first_acc IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'FAIL: No available accommodation found for a destination. All stay bookings rolled back.';
        END IF;

        INSERT INTO travel_agency_2025_stay_booking
            (sb_tr_id, sb_dst_id, sb_acc_id, sb_checkin, sb_checkout, sb_rooms)
        VALUES
            (p_tr_id, v_dst_id, v_first_acc, v_arr, v_dep, p_rooms);
    END LOOP;

    CLOSE cur;

    COMMIT;

    SELECT
        a.acc_name,
        sb.sb_checkin,
        sb.sb_checkout,
        sb.sb_nights,
        sb.sb_total_cost
    FROM travel_agency_2025_stay_booking sb
    JOIN travel_agency_2025_accommodation a ON a.acc_id = sb.sb_acc_id
    WHERE sb.sb_tr_id = p_tr_id
    ORDER BY sb.sb_checkin;

    SELECT
        SUM(sb_total_cost) AS total_stay_cost
    FROM travel_agency_2025_stay_booking
    WHERE sb_tr_id = p_tr_id;
END$$

CREATE PROCEDURE sp_history_revenue_between (
    IN p_date_from DATE,
    IN p_date_to DATE
)
BEGIN
    IF p_date_to < p_date_from THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: date_to must be >= date_from.';
    END IF;

    SELECT SUM(th_total_revenue) AS total_revenue
    FROM travel_agency_2025_trip_history
    WHERE th_departure BETWEEN p_date_from AND p_date_to;
END$$

CREATE PROCEDURE sp_history_dates_by_destinations (
    IN p_dest_count INT
)
BEGIN
    IF p_dest_count < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: destination count must be >= 0.';
    END IF;

    SELECT th_departure, th_return
    FROM travel_agency_2025_trip_history
    WHERE th_destinations_count = p_dest_count
    ORDER BY th_departure;
END$$

CREATE TRIGGER trg_stay_booking_calc
BEFORE INSERT ON travel_agency_2025_stay_booking
FOR EACH ROW
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_nights INT;

    SET v_nights = DATEDIFF(NEW.sb_checkout, NEW.sb_checkin);

    IF v_nights <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: Invalid stay dates (nights <= 0).';
    END IF;

    SELECT acc_price_per_room_night INTO v_price
    FROM travel_agency_2025_accommodation
    WHERE acc_id = NEW.sb_acc_id;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: Accommodation price not found.';
    END IF;

    SET NEW.sb_nights = v_nights;
    SET NEW.sb_total_cost = v_nights * NEW.sb_rooms * v_price;
END$$

CREATE TRIGGER trg_trip_vehicle_validate_endkm
BEFORE UPDATE ON travel_agency_2025_trip_vehicle
FOR EACH ROW
BEGIN
    IF NEW.tv_end_km IS NOT NULL AND NEW.tv_end_km < OLD.tv_start_km THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FAIL: end_km cannot be less than start_km.';
    END IF;
END$$

CREATE TRIGGER trg_trip_vehicle_close_trip
AFTER UPDATE ON travel_agency_2025_trip_vehicle
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);

    IF OLD.tv_end_km IS NULL AND NEW.tv_end_km IS NOT NULL THEN
        SELECT tr_status INTO v_status
        FROM travel_agency_2025_trip
        WHERE tr_id = NEW.tv_tr_id;

        IF v_status = 'COMPLETED' THEN
            UPDATE travel_agency_2025_vehicle
            SET veh_total_km = NEW.tv_end_km,
                veh_status = 'AVAILABLE'
            WHERE veh_id = NEW.tv_veh_id;
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_log_trip_ins
AFTER INSERT ON travel_agency_2025_trip
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_trip', CAST(NEW.tr_id AS CHAR));
END$$

CREATE TRIGGER trg_log_trip_upd
AFTER UPDATE ON travel_agency_2025_trip
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_trip', CAST(NEW.tr_id AS CHAR));
END$$

CREATE TRIGGER trg_log_trip_del
AFTER DELETE ON travel_agency_2025_trip
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_trip', CAST(OLD.tr_id AS CHAR));
END$$

CREATE TRIGGER trg_log_reservation_ins
AFTER INSERT ON travel_agency_2025_reservation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_reservation',
          CONCAT(NEW.res_tr_id, '-', NEW.res_seatnum));
END$$

CREATE TRIGGER trg_log_reservation_upd
AFTER UPDATE ON travel_agency_2025_reservation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_reservation',
          CONCAT(NEW.res_tr_id, '-', NEW.res_seatnum));
END$$

CREATE TRIGGER trg_log_reservation_del
AFTER DELETE ON travel_agency_2025_reservation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_reservation',
          CONCAT(OLD.res_tr_id, '-', OLD.res_seatnum));
END$$

CREATE TRIGGER trg_log_customer_ins
AFTER INSERT ON travel_agency_2025_customer
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_customer', CAST(NEW.cust_id AS CHAR));
END$$

CREATE TRIGGER trg_log_customer_upd
AFTER UPDATE ON travel_agency_2025_customer
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_customer', CAST(NEW.cust_id AS CHAR));
END$$

CREATE TRIGGER trg_log_customer_del
AFTER DELETE ON travel_agency_2025_customer
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_customer', CAST(OLD.cust_id AS CHAR));
END$$

CREATE TRIGGER trg_log_destination_ins
AFTER INSERT ON travel_agency_2025_destination
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_destination', CAST(NEW.dst_id AS CHAR));
END$$

CREATE TRIGGER trg_log_destination_upd
AFTER UPDATE ON travel_agency_2025_destination
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_destination', CAST(NEW.dst_id AS CHAR));
END$$

CREATE TRIGGER trg_log_destination_del
AFTER DELETE ON travel_agency_2025_destination
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_destination', CAST(OLD.dst_id AS CHAR));
END$$

CREATE TRIGGER trg_log_vehicle_ins
AFTER INSERT ON travel_agency_2025_vehicle
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_vehicle', CAST(NEW.veh_id AS CHAR));
END$$

CREATE TRIGGER trg_log_vehicle_upd
AFTER UPDATE ON travel_agency_2025_vehicle
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_vehicle', CAST(NEW.veh_id AS CHAR));
END$$

CREATE TRIGGER trg_log_vehicle_del
AFTER DELETE ON travel_agency_2025_vehicle
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_vehicle', CAST(OLD.veh_id AS CHAR));
END$$

CREATE TRIGGER trg_log_accommodation_ins
AFTER INSERT ON travel_agency_2025_accommodation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_accommodation', CAST(NEW.acc_id AS CHAR));
END$$

CREATE TRIGGER trg_log_accommodation_upd
AFTER UPDATE ON travel_agency_2025_accommodation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_accommodation', CAST(NEW.acc_id AS CHAR));
END$$

CREATE TRIGGER trg_log_accommodation_del
AFTER DELETE ON travel_agency_2025_accommodation
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_accommodation', CAST(OLD.acc_id AS CHAR));
END$$

CREATE TRIGGER trg_log_stay_booking_ins
AFTER INSERT ON travel_agency_2025_stay_booking
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'INSERT', 'travel_agency_2025_stay_booking', CAST(NEW.sb_id AS CHAR));
END$$

CREATE TRIGGER trg_log_stay_booking_upd
AFTER UPDATE ON travel_agency_2025_stay_booking
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'UPDATE', 'travel_agency_2025_stay_booking', CAST(NEW.sb_id AS CHAR));
END$$

CREATE TRIGGER trg_log_stay_booking_del
AFTER DELETE ON travel_agency_2025_stay_booking
FOR EACH ROW
BEGIN
  INSERT INTO travel_agency_2025_dba_log(log_username, log_action, log_table_name, log_pk)
  VALUES (CURRENT_USER(), 'DELETE', 'travel_agency_2025_stay_booking', CAST(OLD.sb_id AS CHAR));
END$$

DELIMITER ;
