
-- =============================================
-- TEST CASES FOR FUNCTIONS, PROCEDURES, TRIGGERS, PACKAGE, AND INDEXES
-- =============================================

-- 1. Test: Trigger trg_auto_patient_id
PROMPT '=== Test: trg_auto_patient_id ==='
INSERT INTO patients (full_name, dob, email, phone, gender)
VALUES ('Trigger Test Patient', TO_DATE('1999-01-01','YYYY-MM-DD'), 'trigger@test.com', '647-000-9999', 'Other');
SELECT patient_id FROM patients WHERE email = 'trigger@test.com';

-- 2. Test: Trigger trg_log_appointment_changes
PROMPT '=== Test: trg_log_appointment_changes ==='
INSERT INTO appointments VALUES (
  seq_appointment_id.NEXTVAL,
  (SELECT patient_id FROM patients WHERE email = 'trigger@test.com'),
  101,
  TO_DATE('2024-09-10', 'YYYY-MM-DD'),
  '10:00 AM',
  'Scheduled',
  'Log trigger test'
);
SELECT * FROM appointment_log WHERE appointment_id = (
  SELECT appointment_id FROM appointments WHERE notes = 'Log trigger test'
);

-- 3. Test: Trigger trg_prevent_double_booking
PROMPT '=== Test: trg_prevent_double_booking ==='
BEGIN
  INSERT INTO appointments VALUES (
    seq_appointment_id.NEXTVAL,
    (SELECT patient_id FROM patients WHERE email = 'trigger@test.com'),
    101,
    TO_DATE('2024-09-10', 'YYYY-MM-DD'),
    '10:00 AM',
    'Scheduled',
    'Should Fail - Double Booking'
  );
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Expected trigger block error: ' || SQLERRM);
END;
/

-- 4. Test: Trigger trg_room_assignment_audit
PROMPT '=== Test: trg_room_assignment_audit ==='
UPDATE rooms SET doctor_id = 102 WHERE room_number = '101A';
SELECT * FROM room_assignment_log WHERE room_id = (
  SELECT room_id FROM rooms WHERE room_number = '101A'
);

-- 5. Test: Procedure create_appointment
PROMPT '=== Test: Procedure create_appointment ==='
DECLARE
  v_pid NUMBER;
BEGIN
  SELECT patient_id INTO v_pid FROM patients WHERE email = 'trigger@test.com';
  create_appointment(v_pid, 102, TO_DATE('2024-09-15','YYYY-MM-DD'), '09:30 AM', 'Procedure creation');
END;
/
SELECT * FROM appointments WHERE notes = 'Procedure creation';

-- 6. Test: Procedure cancel_appointment
PROMPT '=== Test: Procedure cancel_appointment ==='
DECLARE
  v_appt NUMBER;
BEGIN
  SELECT appointment_id INTO v_appt FROM appointments WHERE notes = 'Procedure creation';
  cancel_appointment(v_appt);
END;
/
SELECT status FROM appointments WHERE notes = 'Procedure creation';

-- 7. Test: Procedure get_patient_appointments
PROMPT '=== Test: Procedure get_patient_appointments ==='
DECLARE
  v_cursor SYS_REFCURSOR;
  v_appt_id NUMBER;
  v_doc VARCHAR2(100);
  v_date VARCHAR2(20);
  v_time VARCHAR2(10);
  v_room VARCHAR2(10);
  v_pid NUMBER;
BEGIN
  SELECT patient_id INTO v_pid FROM patients WHERE email = 'trigger@test.com';
  get_patient_appointments(v_pid, v_cursor);
  LOOP
    FETCH v_cursor INTO v_appt_id, v_doc, v_date, v_time, v_room;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Appt: ' || v_appt_id || ', Doctor: ' || v_doc || ', Date: ' || v_date || ', Time: ' || v_time);
  END LOOP;
  CLOSE v_cursor;
END;
/

-- 8. Test: Function count_total_patients
PROMPT '=== Test: Function count_total_patients ==='
SELECT count_total_patients FROM dual;

-- 9. Test: Function get_patient_fullname
PROMPT '=== Test: Function get_patient_fullname ==='
SELECT get_patient_fullname((SELECT patient_id FROM patients WHERE email = 'trigger@test.com')) AS fullname FROM dual;

-- 10. Test: Function get_doctor_room
PROMPT '=== Test: Function get_doctor_room ==='
SELECT get_doctor_room(101) AS room_number FROM dual;

-- 11. Test: Standalone Procedure update_appointment
PROMPT '=== Test: Procedure update_appointment ==='
DECLARE
  v_appt_id NUMBER;
BEGIN
  SELECT appointment_id INTO v_appt_id FROM appointments WHERE notes = 'Procedure creation';
  update_appointment(v_appt_id, 'Rescheduled', 'Updated through test case');
END;
/
SELECT status, notes FROM appointments WHERE appointment_id = (
  SELECT appointment_id FROM appointments WHERE notes = 'Updated through test case'
);

-- 12. Test: Package hospital_pkg.create_appointment
PROMPT '=== Test: hospital_pkg.create_appointment ==='
DECLARE
  v_pid NUMBER;
BEGIN
  SELECT patient_id INTO v_pid FROM patients WHERE email = 'trigger@test.com';
  hospital_pkg.create_appointment(v_pid, 103, TO_DATE('2024-09-20','YYYY-MM-DD'), '10:45 AM', 'Package test');
END;
/
SELECT * FROM appointments WHERE notes = 'Package test';

-- 13. Test: hospital_pkg.cancel_appointment
PROMPT '=== Test: hospital_pkg.cancel_appointment ==='
DECLARE
  v_appt NUMBER;
BEGIN
  SELECT appointment_id INTO v_appt FROM appointments WHERE notes = 'Package test';
  hospital_pkg.cancel_appointment(v_appt);
END;
/
SELECT status FROM appointments WHERE notes = 'Package test';

-- 14. Test: hospital_pkg.get_doctor_name
SELECT hospital_pkg.get_doctor_name(101) AS doctor_name FROM dual;

-- 15. Test: hospital_pkg.get_patient_age
SELECT hospital_pkg.get_patient_age((SELECT patient_id FROM patients WHERE email = 'trigger@test.com')) AS age FROM dual;

-- 16. Test: hospital_pkg.count_appointments_by_status
SELECT hospital_pkg.count_appointments_by_status('Cancelled') AS cancelled_count FROM dual;

-- 17. Test: hospital_pkg.get_doctor_appointment_count
SELECT hospital_pkg.get_doctor_appointment_count(101, TO_DATE('2024-08-01', 'YYYY-MM-DD')) AS appt_count FROM dual;

-- 18. Test: hospital_pkg.get_patient_appointments
PROMPT '=== Test: hospital_pkg.get_patient_appointments ==='
DECLARE
  v_cursor SYS_REFCURSOR;
  v_appt_id NUMBER;
  v_doc VARCHAR2(100);
  v_date VARCHAR2(20);
  v_time VARCHAR2(10);
  v_room VARCHAR2(10);
  v_pid NUMBER;
BEGIN
  SELECT patient_id INTO v_pid FROM patients WHERE email = 'trigger@test.com';
  hospital_pkg.get_patient_appointments(v_pid, v_cursor);
  LOOP
    FETCH v_cursor INTO v_appt_id, v_doc, v_date, v_time, v_room;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Pkg Appt: ' || v_appt_id || ', Doctor: ' || v_doc || ', Date: ' || v_date || ', Time: ' || v_time);
  END LOOP;
  CLOSE v_cursor;
END;
/

-- 19. Index usage validation (explain plan used manually)
PROMPT '=== Test: Index idx_appointments_doctor_date ==='
SELECT * FROM appointments WHERE doctor_id = 101 AND appointment_date = TO_DATE('2024-08-01', 'YYYY-MM-DD');

PROMPT '=== Test: Index idx_patients_fullname ==='
SELECT * FROM patients WHERE full_name = 'Adam Brown';

PROMPT '=== Test: Index idx_doctors_specialty ==='
SELECT * FROM doctors WHERE specialty_id = 1;