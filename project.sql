DROP TABLE appointments CASCADE CONSTRAINTS;
DROP TABLE appointment_log CASCADE CONSTRAINTS;
DROP TABLE rooms CASCADE CONSTRAINTS;
DROP TABLE doctors CASCADE CONSTRAINTS;
DROP TABLE patients CASCADE CONSTRAINTS;
DROP TABLE specialties CASCADE CONSTRAINTS;
DROP TABLE room_assignment_log CASCADE CONSTRAINTS;

-- Drop extra room log sequence if exists (for consistency with triggers below)
DROP SEQUENCE seq_room_log_id;

DROP SEQUENCE seq_specialty_id;
DROP SEQUENCE seq_doctor_id;
DROP SEQUENCE seq_patient_id;
DROP SEQUENCE seq_appointment_id;
DROP SEQUENCE seq_log_id;
DROP SEQUENCE seq_room_id;


-- specialties (Lookup Table)
CREATE TABLE specialties (
  specialty_id NUMBER PRIMARY KEY,
  name VARCHAR2(100) UNIQUE NOT NULL
);


CREATE TABLE doctors (
  doctor_id NUMBER PRIMARY KEY,
  full_name VARCHAR2(100) NOT NULL,
  email VARCHAR2(100) UNIQUE NOT NULL,
  phone VARCHAR2(15),
  room VARCHAR2(10),
  specialty_id NUMBER,
  FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
);

--patients
CREATE TABLE patients (
  patient_id NUMBER PRIMARY KEY,
  full_name VARCHAR2(100) NOT NULL,
  dob DATE NOT NULL,
  email VARCHAR2(100) UNIQUE,
  phone VARCHAR2(15),
  gender VARCHAR2(10)
);

-- appointments
CREATE TABLE appointments (
  appointment_id NUMBER PRIMARY KEY,
  patient_id NUMBER NOT NULL,
  doctor_id NUMBER NOT NULL,
  appointment_date DATE NOT NULL,
  appointment_time VARCHAR2(10) NOT NULL, -- e.g., '09:30 AM'
  status VARCHAR2(20) DEFAULT 'Scheduled',
  notes VARCHAR2(255),
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- appointment_log (Audit Table)
CREATE TABLE appointment_log (
  log_id NUMBER PRIMARY KEY,
  appointment_id NUMBER,
  operation_type VARCHAR2(20), -- 'INSERT', 'UPDATE', 'DELETE'
  changed_by VARCHAR2(100),
  changed_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  old_status VARCHAR2(20),
  new_status VARCHAR2(20)
);

-- rooms tables
CREATE TABLE rooms (
  room_id NUMBER PRIMARY KEY,
  room_number VARCHAR2(10) UNIQUE NOT NULL,
  doctor_id NUMBER,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE room_assignment_log (
  log_id NUMBER PRIMARY KEY,
  room_id NUMBER,
  doctor_id NUMBER,
  operation_type VARCHAR2(10), -- INSERT or UPDATE
  changed_on TIMESTAMP DEFAULT SYSTIMESTAMP,
  changed_by VARCHAR2(100)
);
-- =============================================
-- SEQUENCES: Auto-increments 
-- =============================================
CREATE SEQUENCE seq_specialty_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_doctor_id START WITH 101 INCREMENT BY 1;
CREATE SEQUENCE seq_patient_id START WITH 1001 INCREMENT BY 1;
CREATE SEQUENCE seq_appointment_id START WITH 5001 INCREMENT BY 1;
CREATE SEQUENCE seq_log_id START WITH 9001 INCREMENT BY 1;
CREATE SEQUENCE seq_room_id START WITH 201 INCREMENT BY 1;

-- =============================================
-- TRIGGER 1: Auto-generate patient_id on INSERT
-- =============================================
CREATE OR REPLACE TRIGGER trg_auto_patient_id
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
  IF :NEW.patient_id IS NULL THEN
    SELECT seq_patient_id.NEXTVAL INTO :NEW.patient_id FROM dual;
  END IF;
END;
/

-- Sequence for room_assignment_log trigger (for audit logs)
CREATE SEQUENCE seq_room_log_id START WITH 10001 INCREMENT BY 1;


-- insert data in speciality table
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Cardiology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Dermatology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Neurology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Pediatrics');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Orthopedics');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Oncology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Psychiatry');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Gastroenterology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Endocrinology');
INSERT INTO specialties VALUES (seq_specialty_id.NEXTVAL, 'Urology');


INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Alice Thompson', 'alice.t@hospital.com', '416-555-1001', 1);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '101A', (SELECT doctor_id FROM doctors WHERE email = 'alice.t@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Bob Mehta', 'bob.m@hospital.com', '416-555-1002', 2);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '102B', (SELECT doctor_id FROM doctors WHERE email = 'bob.m@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Clara Zhang', 'clara.z@hospital.com', '416-555-1003', 3);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '103C', (SELECT doctor_id FROM doctors WHERE email = 'clara.z@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Daniel Gomez', 'daniel.g@hospital.com', '416-555-1004', 4);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '104D', (SELECT doctor_id FROM doctors WHERE email = 'daniel.g@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Eva Singh', 'eva.s@hospital.com', '416-555-1005', 5);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '105E', (SELECT doctor_id FROM doctors WHERE email = 'eva.s@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Farhan Khan', 'farhan.k@hospital.com', '416-555-1006', 1);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '106F', (SELECT doctor_id FROM doctors WHERE email = 'farhan.k@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Grace Kim', 'grace.k@hospital.com', '416-555-1007', 2);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '107G', (SELECT doctor_id FROM doctors WHERE email = 'grace.k@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Henry Chu', 'henry.c@hospital.com', '416-555-1008', 3);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '108H', (SELECT doctor_id FROM doctors WHERE email = 'henry.c@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Irina Novak', 'irina.n@hospital.com', '416-555-1009', 4);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '109I', (SELECT doctor_id FROM doctors WHERE email = 'irina.n@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. John Patel', 'john.p@hospital.com', '416-555-1010', 5);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '110J', (SELECT doctor_id FROM doctors WHERE email = 'john.p@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Kevin Roy', 'kevin.r@hospital.com', '416-555-1011', 6);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '111K', (SELECT doctor_id FROM doctors WHERE email = 'kevin.r@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Lily Chen', 'lily.c@hospital.com', '416-555-1012', 7);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '112L', (SELECT doctor_id FROM doctors WHERE email = 'lily.c@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Mark Singh', 'mark.s@hospital.com', '416-555-1013', 8);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '113M', (SELECT doctor_id FROM doctors WHERE email = 'mark.s@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Nia Hassan', 'nia.h@hospital.com', '416-555-1014', 9);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '114N', (SELECT doctor_id FROM doctors WHERE email = 'nia.h@hospital.com'));

INSERT INTO doctors (doctor_id, full_name, email, phone, specialty_id)
VALUES (seq_doctor_id.NEXTVAL, 'Dr. Omar Silva', 'omar.s@hospital.com', '416-555-1015', 10);
INSERT INTO rooms (room_id, room_number, doctor_id)
VALUES (seq_room_id.NEXTVAL, '115O', (SELECT doctor_id FROM doctors WHERE email = 'omar.s@hospital.com'));


INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Adam Brown', TO_DATE('1990-03-12','YYYY-MM-DD'), 'adam.b@example.com', '647-111-2001', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Betty Carter', TO_DATE('1985-07-08','YYYY-MM-DD'), 'betty.c@example.com', '647-111-2002', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Charlie Davis', TO_DATE('1978-12-25','YYYY-MM-DD'), 'charlie.d@example.com', '647-111-2003', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Diana Evans', TO_DATE('2000-11-05','YYYY-MM-DD'), 'diana.e@example.com', '647-111-2004', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Edward Ford', TO_DATE('1967-09-20','YYYY-MM-DD'), 'edward.f@example.com', '647-111-2005', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Fiona Green', TO_DATE('1995-01-30','YYYY-MM-DD'), 'fiona.g@example.com', '647-111-2006', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'George Hill', TO_DATE('1983-06-10','YYYY-MM-DD'), 'george.h@example.com', '647-111-2007', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Hannah Ivy', TO_DATE('1972-04-17','YYYY-MM-DD'), 'hannah.i@example.com', '647-111-2008', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Ian Jacobs', TO_DATE('1999-02-28','YYYY-MM-DD'), 'ian.j@example.com', '647-111-2009', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Jasmine King', TO_DATE('1988-08-14','YYYY-MM-DD'), 'jasmine.k@example.com', '647-111-2010', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Kyle Brody', TO_DATE('1992-10-15','YYYY-MM-DD'), 'kyle.b@example.com', '647-111-2011', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Lara Quinn', TO_DATE('1993-12-01','YYYY-MM-DD'), 'lara.q@example.com', '647-111-2012', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Mohan Yadav', TO_DATE('1981-05-19','YYYY-MM-DD'), 'mohan.y@example.com', '647-111-2013', 'Male'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Nina Perry', TO_DATE('2002-03-23','YYYY-MM-DD'), 'nina.p@example.com', '647-111-2014', 'Female'
);
INSERT INTO patients (
  full_name, dob, email, phone, gender
) VALUES (
  'Oscar Li', TO_DATE('1996-09-17','YYYY-MM-DD'), 'oscar.l@example.com', '647-111-2015', 'Male'
);


-- insert into appointments
-- Now using patient_id subqueries for correct assignment after trigger
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Adam Brown'),
  101,
  TO_DATE('2024-08-01', 'YYYY-MM-DD'),
  '10:00 AM',
  'Scheduled',
  'Initial visit'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Betty Carter'),
  102,
  TO_DATE('2024-08-01', 'YYYY-MM-DD'),
  '11:00 AM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Charlie Davis'),
  103,
  TO_DATE('2024-08-02', 'YYYY-MM-DD'),
  '02:30 PM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Diana Evans'),
  104,
  TO_DATE('2024-08-02', 'YYYY-MM-DD'),
  '01:00 PM',
  'Scheduled',
  'Flu symptoms'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Edward Ford'),
  105,
  TO_DATE('2024-08-03', 'YYYY-MM-DD'),
  '09:00 AM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Fiona Green'),
  106,
  TO_DATE('2024-08-03', 'YYYY-MM-DD'),
  '10:30 AM',
  'Scheduled',
  'Follow-up'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'George Hill'),
  107,
  TO_DATE('2024-08-04', 'YYYY-MM-DD'),
  '12:00 PM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Hannah Ivy'),
  108,
  TO_DATE('2024-08-04', 'YYYY-MM-DD'),
  '03:00 PM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Ian Jacobs'),
  109,
  TO_DATE('2024-08-05', 'YYYY-MM-DD'),
  '11:15 AM',
  'Scheduled',
  'Back pain'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Jasmine King'),
  110,
  TO_DATE('2024-08-05', 'YYYY-MM-DD'),
  '04:00 PM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Kyle Brody'),
  111,
  TO_DATE('2024-08-06', 'YYYY-MM-DD'),
  '10:30 AM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Lara Quinn'),
  112,
  TO_DATE('2024-08-06', 'YYYY-MM-DD'),
  '11:30 AM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Mohan Yadav'),
  113,
  TO_DATE('2024-08-07', 'YYYY-MM-DD'),
  '09:00 AM',
  'Scheduled',
  NULL
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Nina Perry'),
  114,
  TO_DATE('2024-08-07', 'YYYY-MM-DD'),
  '02:00 PM',
  'Scheduled',
  NULL
);
-- Additional completed and cancelled appointments
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Mohan Yadav'),
  113,
  TO_DATE('2024-07-29', 'YYYY-MM-DD'),
  '09:30 AM',
  'Completed',
  'Routine check-up'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Nina Perry'),
  114,
  TO_DATE('2024-07-30', 'YYYY-MM-DD'),
  '11:00 AM',
  'Cancelled',
  'Patient unavailable'
);
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE full_name = 'Oscar Li'),
  115,
  TO_DATE('2024-08-08', 'YYYY-MM-DD'),
  '01:30 PM',
  'Scheduled',
  'Follow-up'
);

-- insert into rooms
-- Assuming seq_room_id is already created
-- Room insertions are now handled above, immediately after doctor insertion, using the new doctor_id.

-- Appointment log entries (using appointment_id subqueries for robust assignment)
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Adam Brown') AND doctor_id = 101 AND appointment_date = TO_DATE('2024-08-01', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Betty Carter') AND doctor_id = 102 AND appointment_date = TO_DATE('2024-08-01', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Charlie Davis') AND doctor_id = 103 AND appointment_date = TO_DATE('2024-08-02', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Diana Evans') AND doctor_id = 104 AND appointment_date = TO_DATE('2024-08-02', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Edward Ford') AND doctor_id = 105 AND appointment_date = TO_DATE('2024-08-03', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Kyle Brody') AND doctor_id = 111 AND appointment_date = TO_DATE('2024-08-06', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Lara Quinn') AND doctor_id = 112 AND appointment_date = TO_DATE('2024-08-06', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Mohan Yadav') AND doctor_id = 113 AND appointment_date = TO_DATE('2024-08-07', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Nina Perry') AND doctor_id = 114 AND appointment_date = TO_DATE('2024-08-07', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Oscar Li') AND doctor_id = 115 AND appointment_date = TO_DATE('2024-08-08', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Scheduled'
);
-- Log entries for completed and cancelled appointments above
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Mohan Yadav') AND doctor_id = 113 AND appointment_date = TO_DATE('2024-07-29', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Completed'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Nina Perry') AND doctor_id = 114 AND appointment_date = TO_DATE('2024-07-30', 'YYYY-MM-DD')),
  'INSERT', 'admin_user', SYSTIMESTAMP, NULL, 'Cancelled'
);

-- Simulated updates/cancellations (example for a few, adjust as needed)
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Charlie Davis') AND doctor_id = 103 AND appointment_date = TO_DATE('2024-08-02', 'YYYY-MM-DD')),
  'UPDATE', 'receptionist', SYSTIMESTAMP, 'Scheduled', 'Rescheduled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Fiona Green') AND doctor_id = 106 AND appointment_date = TO_DATE('2024-08-03', 'YYYY-MM-DD')),
  'UPDATE', 'receptionist', SYSTIMESTAMP, 'Scheduled', 'Cancelled'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'George Hill') AND doctor_id = 107 AND appointment_date = TO_DATE('2024-08-04', 'YYYY-MM-DD')),
  'UPDATE', 'admin_user', SYSTIMESTAMP, 'Scheduled', 'Completed'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Ian Jacobs') AND doctor_id = 109 AND appointment_date = TO_DATE('2024-08-05', 'YYYY-MM-DD')),
  'UPDATE', 'admin_user', SYSTIMESTAMP, 'Scheduled', 'Completed'
);
INSERT INTO appointment_log VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Jasmine King') AND doctor_id = 110 AND appointment_date = TO_DATE('2024-08-05', 'YYYY-MM-DD')),
  'UPDATE', 'receptionist', SYSTIMESTAMP, 'Scheduled', 'No-Show'
);

-- Manually cancel an appointment and log the change (example for Oscar Li's appointment)
UPDATE appointments
SET status = 'Cancelled'
WHERE appointment_id = (
  SELECT appointment_id FROM appointments
  WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Oscar Li')
    AND doctor_id = 115
    AND appointment_date = TO_DATE('2024-08-08', 'YYYY-MM-DD')
);

INSERT INTO appointment_log (
  log_id, appointment_id, operation_type, changed_by, changed_on, old_status, new_status
) VALUES (
  seq_log_id.NEXTVAL,
  (SELECT appointment_id FROM appointments
    WHERE patient_id = (SELECT patient_id FROM patients WHERE full_name = 'Oscar Li')
      AND doctor_id = 115
      AND appointment_date = TO_DATE('2024-08-08', 'YYYY-MM-DD')
  ),
  'UPDATE',
  'admin_user',
  SYSTIMESTAMP,
  'Scheduled',
  'Cancelled'
);


-- Requirement: Use sequence to UPDATE a table
-- Assign a new appointment_id to an existing appointment using the sequence

UPDATE appointments
SET appointment_id = seq_appointment_id.NEXTVAL
WHERE appointment_id = 5001;


-- Indexing 
-- Index 1: Faster search for appointments by doctor and date
CREATE INDEX idx_appointments_doctor_date 
ON appointments (doctor_id, appointment_date);

-- Index 2: Faster lookup of patient by full name
CREATE INDEX idx_patients_fullname 
ON patients (full_name);

-- Optional Index 3 (bonus): Search doctors by specialty
CREATE INDEX idx_doctors_specialty 
ON doctors (specialty_id);


-- =======================================================
-- TRIGGER 2: Log appointment INSERT/UPDATE/DELETE changes
-- =======================================================
CREATE OR REPLACE TRIGGER trg_log_appointment_changes
AFTER INSERT OR UPDATE OR DELETE ON appointments
FOR EACH ROW
DECLARE
  v_old_status VARCHAR2(20);
  v_new_status VARCHAR2(20);
  v_action VARCHAR2(10);
  v_user VARCHAR2(100) := USER;
BEGIN
  IF INSERTING THEN
    v_action := 'INSERT';
    v_old_status := NULL;
    v_new_status := :NEW.status;
  ELSIF UPDATING THEN
    v_action := 'UPDATE';
    v_old_status := :OLD.status;
    v_new_status := :NEW.status;
  ELSIF DELETING THEN
    v_action := 'DELETE';
    v_old_status := :OLD.status;
    v_new_status := NULL;
  END IF;

  INSERT INTO appointment_log (
    log_id, appointment_id, operation_type,
    changed_by, changed_on, old_status, new_status
  ) VALUES (
    seq_log_id.NEXTVAL,
    NVL(:NEW.appointment_id, :OLD.appointment_id),
    v_action,
    v_user,
    SYSTIMESTAMP,
    v_old_status,
    v_new_status
  );
END;
/



-- =============================================
-- TRIGGER 3: Compound trigger to prevent double-booking of doctor
-- =============================================
CREATE OR REPLACE TRIGGER trg_prevent_double_booking
FOR INSERT OR UPDATE ON appointments
COMPOUND TRIGGER

  TYPE appointment_key IS RECORD (
    doctor_id appointments.doctor_id%TYPE,
    appointment_date appointments.appointment_date%TYPE,
    appointment_time appointments.appointment_time%TYPE,
    appointment_id appointments.appointment_id%TYPE
  );

  TYPE appointment_table IS TABLE OF appointment_key;
  new_appts appointment_table := appointment_table();

  AFTER EACH ROW IS
  BEGIN
    IF :NEW.status = 'Scheduled' THEN
      new_appts.EXTEND;
      new_appts(new_appts.COUNT).doctor_id := :NEW.doctor_id;
      new_appts(new_appts.COUNT).appointment_date := :NEW.appointment_date;
      new_appts(new_appts.COUNT).appointment_time := :NEW.appointment_time;
      new_appts(new_appts.COUNT).appointment_id := :NEW.appointment_id;
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_count INTEGER;
  BEGIN
    FOR i IN 1 .. new_appts.COUNT LOOP
      SELECT COUNT(*) INTO v_count
      FROM appointments
      WHERE doctor_id = new_appts(i).doctor_id
        AND appointment_date = new_appts(i).appointment_date
        AND appointment_time = new_appts(i).appointment_time
        AND appointment_id != new_appts(i).appointment_id;

      IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'This doctor already has an appointment at that time.');
      END IF;
    END LOOP;
  END AFTER STATEMENT;

END trg_prevent_double_booking;
/

-- =============================================
-- TRIGGER 4: Trigger to log INSERT or UPDATE in rooms
-- =============================================
CREATE OR REPLACE TRIGGER trg_room_assignment_audit
AFTER INSERT OR UPDATE ON rooms
FOR EACH ROW
DECLARE
  v_action VARCHAR2(10);
  v_user VARCHAR2(100) := USER;
BEGIN
  IF INSERTING THEN
    v_action := 'INSERT';
  ELSIF UPDATING THEN
    v_action := 'UPDATE';
  END IF;

  INSERT INTO room_assignment_log (
    log_id,
    room_id,
    doctor_id,
    operation_type,
    changed_on,
    changed_by
  ) VALUES (
    seq_room_log_id.NEXTVAL,
    :NEW.room_id,
    :NEW.doctor_id,
    v_action,
    SYSTIMESTAMP,
    v_user
  );
END;
/


-- =============================================
-- PROCEDURE 1: Creates an appointment with validation
-- =============================================
CREATE OR REPLACE PROCEDURE create_appointment (
  p_patient_id       IN appointments.patient_id%TYPE,
  p_doctor_id        IN appointments.doctor_id%TYPE,
  p_date             IN appointments.appointment_date%TYPE,
  p_time             IN appointments.appointment_time%TYPE,
  p_notes            IN appointments.notes%TYPE
)
IS
  -- Cursor to check for double booking
  CURSOR c_check_conflict IS
    SELECT COUNT(*) AS conflict_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = p_time;

  v_conflict_count NUMBER;
BEGIN
  -- Check for conflicting appointments
  OPEN c_check_conflict;
  FETCH c_check_conflict INTO v_conflict_count;
  CLOSE c_check_conflict;

  IF v_conflict_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Doctor already has an appointment at that time.');
  ELSE
    INSERT INTO appointments (
      appointment_id,
      patient_id,
      doctor_id,
      appointment_date,
      appointment_time,
      status,
      notes
    ) VALUES (
      seq_appointment_id.NEXTVAL,
      p_patient_id,
      p_doctor_id,
      p_date,
      p_time,
      'Scheduled',
      p_notes
    );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in create_appointment: ' || SQLERRM);
END;
/


-- =============================================
-- PROCEDURE 2: Cancels an appointment and logs the event
-- =============================================
CREATE OR REPLACE PROCEDURE cancel_appointment (
  p_appointment_id IN appointments.appointment_id%TYPE
)
IS
  v_old_status appointments.status%TYPE;
BEGIN
  SELECT status INTO v_old_status
  FROM appointments
  WHERE appointment_id = p_appointment_id;

  UPDATE appointments
  SET status = 'Cancelled'
  WHERE appointment_id = p_appointment_id;

  INSERT INTO appointment_log (
    log_id, appointment_id, operation_type, changed_by, changed_on, old_status, new_status
  ) VALUES (
    seq_log_id.NEXTVAL,
    p_appointment_id,
    'UPDATE',
    USER,
    SYSTIMESTAMP,
    v_old_status,
    'Cancelled'
  );

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Appointment not found.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in cancel_appointment: ' || SQLERRM);
END;
/

-- =============================================
-- PROCEDURE 3: Get all appointments for a patient (returns a cursor)
-- =============================================
CREATE OR REPLACE PROCEDURE get_patient_appointments (
  p_patient_id IN appointments.patient_id%TYPE,
  p_cursor OUT SYS_REFCURSOR
)
IS
BEGIN
  OPEN p_cursor FOR
    SELECT 
      a.appointment_id,
      d.full_name AS doctor_name,
      TO_CHAR(a.appointment_date, 'YYYY-MM-DD') AS appt_date,
      a.appointment_time,
      r.room_number AS room_number
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.doctor_id
    LEFT JOIN rooms r ON d.doctor_id = r.doctor_id
    WHERE a.patient_id = p_patient_id
    ORDER BY a.appointment_date, a.appointment_time;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in get_patient_appointments: ' || SQLERRM);
END;
/


-- =============================================
-- FUNCTION 1: Count Total Patients
-- =============================================
CREATE OR REPLACE FUNCTION count_total_patients RETURN NUMBER
IS
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM patients;
  RETURN v_total;
END;
/

-- =============================================
-- FUNCTION 2: Get patient's full name by ID
-- =============================================
CREATE OR REPLACE FUNCTION get_patient_fullname (
  p_patient_id IN patients.patient_id%TYPE
) RETURN VARCHAR2
IS
  v_name patients.full_name%TYPE;
BEGIN
  SELECT full_name INTO v_name
  FROM patients
  WHERE patient_id = p_patient_id;

  RETURN v_name;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Unknown Patient';
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in get_patient_fullname: ' || SQLERRM);
    RETURN NULL;
END;
/

-- =============================================
-- FUNCTION 3: Get Room Number Assigned to Doctor
-- =============================================
CREATE OR REPLACE FUNCTION get_doctor_room (
  p_doctor_id IN doctors.doctor_id%TYPE
) RETURN VARCHAR2
IS
  v_room rooms.room_number%TYPE;
BEGIN
  SELECT room_number INTO v_room
  FROM rooms
  WHERE doctor_id = p_doctor_id;

  RETURN v_room;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'No room assigned';
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in get_doctor_room: ' || SQLERRM);
    RETURN NULL;
END;
/


-- ================================
-- PACKAGE: hospital_pkg
-- ================================

CREATE OR REPLACE PACKAGE hospital_pkg IS
  -- a. Procedures
  PROCEDURE create_appointment (
    p_patient_id IN appointments.patient_id%TYPE,
    p_doctor_id  IN appointments.doctor_id%TYPE,
    p_date       IN appointments.appointment_date%TYPE,
    p_time       IN appointments.appointment_time%TYPE,
    p_notes      IN appointments.notes%TYPE
  );

  PROCEDURE cancel_appointment (
    p_appointment_id IN appointments.appointment_id%TYPE
  );

  -- b. Functions
  FUNCTION get_doctor_name (
    p_doctor_id IN doctors.doctor_id%TYPE
  ) RETURN VARCHAR2;

  FUNCTION get_patient_age (
    p_patient_id IN patients.patient_id%TYPE
  ) RETURN NUMBER;

  FUNCTION count_appointments_by_status (
    p_status IN appointments.status%TYPE
  ) RETURN NUMBER;

  -- Function to get doctor appointment count
  FUNCTION get_doctor_appointment_count (
    p_doctor_id IN appointments.doctor_id%TYPE,
    p_date IN appointments.appointment_date%TYPE
  ) RETURN NUMBER;

  -- d. Get all appointments for a patient (returns a cursor)
  PROCEDURE get_patient_appointments (
    p_patient_id IN appointments.patient_id%TYPE,
    p_cursor OUT SYS_REFCURSOR
  );

  -- c. Global Variable
  g_user VARCHAR2(100) := USER;

END hospital_pkg;
/

CREATE OR REPLACE PACKAGE BODY hospital_pkg IS

  -- Internal Private Cursor (for demonstration)
  CURSOR c_conflict_check (
    p_doc_id  doctors.doctor_id%TYPE,
    p_date    appointments.appointment_date%TYPE,
    p_time    appointments.appointment_time%TYPE
  ) IS
    SELECT COUNT(*) AS cnt
    FROM appointments
    WHERE doctor_id = p_doc_id
      AND appointment_date = p_date
      AND appointment_time = p_time;

  -- a. Procedure 1
  PROCEDURE create_appointment (
    p_patient_id IN appointments.patient_id%TYPE,
    p_doctor_id  IN appointments.doctor_id%TYPE,
    p_date       IN appointments.appointment_date%TYPE,
    p_time       IN appointments.appointment_time%TYPE,
    p_notes      IN appointments.notes%TYPE
  )
  IS
    v_count INTEGER;
  BEGIN
    OPEN c_conflict_check(p_doctor_id, p_date, p_time);
    FETCH c_conflict_check INTO v_count;
    CLOSE c_conflict_check;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Doctor already has an appointment at that time.');
    ELSE
      INSERT INTO appointments (
        appointment_id, patient_id, doctor_id,
        appointment_date, appointment_time, status, notes
      ) VALUES (
        seq_appointment_id.NEXTVAL,
        p_patient_id,
        p_doctor_id,
        p_date,
        p_time,
        'Scheduled',
        p_notes
      );
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in create_appointment: ' || SQLERRM);
  END;

  -- a. Procedure 2
  PROCEDURE cancel_appointment (
    p_appointment_id IN appointments.appointment_id%TYPE
  )
  IS
    v_old_status appointments.status%TYPE;
  BEGIN
    -- Retrieve the current status of the appointment
    SELECT status INTO v_old_status
    FROM appointments
    WHERE appointment_id = p_appointment_id;

    -- Check if already cancelled or completed
    IF v_old_status IN ('Cancelled', 'Completed') THEN
      DBMS_OUTPUT.PUT_LINE('Appointment already ' || v_old_status || '. No update made.');
      RETURN;
    END IF;

    -- Update status to 'Cancelled'
    UPDATE appointments
    SET status = 'Cancelled'
    WHERE appointment_id = p_appointment_id;

    -- Log the status change
    INSERT INTO appointment_log (
      log_id, appointment_id, operation_type, changed_by, changed_on, old_status, new_status
    )
    VALUES (
      seq_log_id.NEXTVAL,
      p_appointment_id,
      'UPDATE',
      g_user,
      SYSTIMESTAMP,
      v_old_status,
      'Cancelled'
    );

    DBMS_OUTPUT.PUT_LINE('Appointment cancelled successfully.');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Appointment not found.');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in cancel_appointment: ' || SQLERRM);
  END;

  -- a. Procedure 3
  PROCEDURE get_patient_appointments (
    p_patient_id IN appointments.patient_id%TYPE,
    p_cursor OUT SYS_REFCURSOR
  )
  IS
  BEGIN
    OPEN p_cursor FOR
      SELECT 
        a.appointment_id,
        d.full_name AS doctor_name,
        TO_CHAR(a.appointment_date, 'YYYY-MM-DD') AS appt_date,
        a.appointment_time,
        r.room_number AS room_number
      FROM appointments a
      JOIN doctors d ON a.doctor_id = d.doctor_id
      LEFT JOIN rooms r ON d.doctor_id = r.doctor_id
      WHERE a.patient_id = p_patient_id
      ORDER BY a.appointment_date, a.appointment_time;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in get_patient_appointments: ' || SQLERRM);
  END;

  -- b. Function 1
  FUNCTION get_doctor_name (
    p_doctor_id IN doctors.doctor_id%TYPE
  ) RETURN VARCHAR2
  IS
    v_name doctors.full_name%TYPE;
  BEGIN
    SELECT full_name INTO v_name
    FROM doctors
    WHERE doctor_id = p_doctor_id;

    RETURN v_name;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'Unknown Doctor';
    WHEN OTHERS THEN
      RETURN 'Error: ' || SQLERRM;
  END;

  -- b. Function 2
  FUNCTION get_patient_age (
    p_patient_id IN patients.patient_id%TYPE
  ) RETURN NUMBER
  IS
    v_dob patients.dob%TYPE;
    v_age NUMBER;
  BEGIN
    SELECT dob INTO v_dob
    FROM patients
    WHERE patient_id = p_patient_id;

    v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, v_dob)/12);

    RETURN v_age;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN -1;
  END;

  -- b. Function 3
  FUNCTION count_appointments_by_status (
    p_status IN appointments.status%TYPE
  ) RETURN NUMBER
  IS
    v_total NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_total
    FROM appointments
    WHERE status = p_status;

    RETURN v_total;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN -1;
  END;

  -- b. Function 4
  FUNCTION get_doctor_appointment_count (
    p_doctor_id IN appointments.doctor_id%TYPE,
    p_date IN appointments.appointment_date%TYPE
  ) RETURN NUMBER
  IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND TRUNC(appointment_date) = TRUNC(p_date);

    RETURN v_count;

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error in get_doctor_appointment_count: ' || SQLERRM);
      RETURN -1;
  END;

END hospital_pkg;
/


-- insert into room_assignment_log for new rooms
INSERT INTO room_assignment_log VALUES (seq_room_log_id.NEXTVAL, 211, 111, 'INSERT', SYSTIMESTAMP, 'admin_user');
INSERT INTO room_assignment_log VALUES (seq_room_log_id.NEXTVAL, 212, 112, 'INSERT', SYSTIMESTAMP, 'admin_user');
INSERT INTO room_assignment_log VALUES (seq_room_log_id.NEXTVAL, 213, 113, 'INSERT', SYSTIMESTAMP, 'admin_user');
INSERT INTO room_assignment_log VALUES (seq_room_log_id.NEXTVAL, 214, 114, 'INSERT', SYSTIMESTAMP, 'admin_user');
INSERT INTO room_assignment_log VALUES (seq_room_log_id.NEXTVAL, 215, 115, 'INSERT', SYSTIMESTAMP, 'admin_user');
-- =============================================
-- Standalone Procedure: update_appointment
-- =============================================
CREATE OR REPLACE PROCEDURE update_appointment(
  p_appointment_id IN NUMBER,
  p_status         IN VARCHAR2,
  p_remarks        IN VARCHAR2
) AS
BEGIN
  UPDATE appointments
  SET status  = p_status,
      notes   = p_remarks
  WHERE appointment_id = p_appointment_id;

  COMMIT;
END;
/