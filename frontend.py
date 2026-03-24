from multiprocessing import connection
import tkinter as tk
from tkinter import messagebox
import cx_Oracle
import re
from datetime import datetime
import os
from dotenv import load_dotenv

# Load the variables from the .env file
load_dotenv()

# We will fix this path in Step 3!
cx_Oracle.init_oracle_client(lib_dir=r"C:\oracle\instantclient_21_13")

# Oracle connection config pulling from environment variables
username = os.getenv("DB_USERNAME")
password = os.getenv("DB_PASSWORD")
dsn = os.getenv("DB_DSN")

# Connect to Oracle
def get_connection():
    return cx_Oracle.connect(username, password, dsn)

# Function: Book Appointment
def book_appointment():
    pid = entry_patient_id.get()
    did = entry_doctor_id.get()
    date_str = entry_date.get()
    time = entry_time.get()
    reason = entry_reason.get()

    date_pattern = r"^\d{4}-\d{2}-\d{2}$"
    if not re.match(date_pattern, date_str.strip()):
        messagebox.showerror("Input Error", "Date must be in YYYY-MM-DD format.")
        return

    try:
        date_obj = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
    except ValueError:
        messagebox.showerror("Input Error", "Invalid date format. Use YYYY-MM-DD.")
        return

    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.callproc("hospital_pkg.create_appointment", [int(pid), int(did), date_obj, time.strip(), reason.strip()])
        conn.commit()
        messagebox.showinfo("Success", "Appointment booked successfully.")
    except cx_Oracle.DatabaseError as e:
        messagebox.showerror("Error", str(e))
    finally:
        try:
            cur.close()
            conn.close()
        except:
            pass

# Additional functions for new features
def view_appointments():
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT a.appointment_id, p.full_name, d.full_name, a.appointment_date, a.appointment_time, a.status
            FROM appointments a
            JOIN patients p ON a.patient_id = p.patient_id
            JOIN doctors d ON a.doctor_id = d.doctor_id
            ORDER BY a.appointment_date
        """)
        records = cur.fetchall()

        conn.commit()  # ensure we get latest data

        if not records:
            messagebox.showinfo("All Appointments", "No appointments found.")
            return

        # Create a new Toplevel window
        win = tk.Toplevel(root)
        win.title("All Appointments")

        listbox_frame = tk.Frame(win)
        listbox_frame.pack(fill=tk.BOTH, expand=True)

        scrollbar = tk.Scrollbar(listbox_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        listbox = tk.Listbox(listbox_frame, yscrollcommand=scrollbar.set)
        listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=listbox.yview)

        for r in records:
            listbox.insert(tk.END, f"Appointment ID: {r[0]}")
            listbox.insert(tk.END, f"Patient: {r[1]}")
            listbox.insert(tk.END, f"Doctor: {r[2]}")
            listbox.insert(tk.END, f"Date: {r[3].strftime('%Y-%m-%d') if isinstance(r[3], datetime) else r[3]}")
            listbox.insert(tk.END, f"Time: {r[4]}")
            listbox.insert(tk.END, f"Status: {r[5]}")
            listbox.insert(tk.END, "-"*40)
    except cx_Oracle.DatabaseError as e:
        messagebox.showerror("Error", str(e))

def get_doctor_info():
    try:
        did = int(entry_doctor_id.get())
        if not isinstance(did, int):
            messagebox.showerror("Input Error", "Doctor ID must be a number.")
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT full_name, email, phone FROM doctors WHERE doctor_id = :1", [did])
        doc = cur.fetchone()
        if doc:
            messagebox.showinfo("Doctor Info", f"Name: {doc[0]}\nEmail: {doc[1]}\nPhone: {doc[2]}")
        else:
            messagebox.showinfo("Doctor Info", "No doctor found.")
    except ValueError:
        messagebox.showerror("Input Error", "Doctor ID must be a number.")
    except cx_Oracle.DatabaseError as e:
        messagebox.showerror("Error", str(e))

def get_patient_info():
    try:
        pid = entry_patient_id.get()
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT full_name, email, phone, gender FROM patients WHERE patient_id = :1", [pid])
        pat = cur.fetchone()
        if pat:
            messagebox.showinfo("Patient Info", f"Name: {pat[0]}\nEmail: {pat[1]}\nPhone: {pat[2]}\nGender: {pat[3]}")
        else:
            messagebox.showinfo("Patient Info", "No patient found.")
    except cx_Oracle.DatabaseError as e:
        messagebox.showerror("Error", str(e))

from tkinter import simpledialog
def cancel_appointment():
    try:
        appt_id = simpledialog.askinteger("Cancel Appointment", "Enter Appointment ID to Cancel:")
        if not appt_id:
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.callproc("hospital_pkg.cancel_appointment", [appt_id])
        conn.commit()
        messagebox.showinfo("Cancelled", "Appointment cancelled successfully.")
        show_view_appointments_screen()
    except cx_Oracle.DatabaseError as e:
        messagebox.showerror("Error", str(e))

### --- Redesigned GUI for Multiple Screens ---
root = tk.Tk()
root.title("Hospital Appointment System")
DEFAULT_FONT = ("Segoe UI", 12)
PAD = 8

# --- Helper to clear root window ---
def clear_root():
    for widget in root.winfo_children():
        widget.destroy()

# --- Welcome Screen ---
def show_welcome_screen():
    clear_root()
    root.deiconify()
    tk.Label(root, text="Welcome to the Hospital Appointment System", font=("Segoe UI", 18, "bold")).pack(pady=24)
    nav = tk.Frame(root)
    nav.pack(pady=6)
    tk.Button(nav, text="Patient Management", font=DEFAULT_FONT, width=22, command=show_patient_management_screen).grid(row=0, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Doctor Management", font=DEFAULT_FONT, width=22, command=show_doctor_management_screen).grid(row=1, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Book Appointment", font=DEFAULT_FONT, width=22, command=show_appointment_booking_screen).grid(row=2, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="View Appointments", font=DEFAULT_FONT, width=22, command=show_appointment_view_screen).grid(row=3, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Update Appointment", font=DEFAULT_FONT, width=22, command=show_update_appointment_screen).grid(row=4, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Cancel Appointment", font=DEFAULT_FONT, width=22, command=show_cancel_appointment_screen).grid(row=5, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Reports", font=DEFAULT_FONT, width=22, command=show_reports_screen).grid(row=6, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Procedures/Functions", font=DEFAULT_FONT, width=22, command=show_test_functions_screen).grid(row=7, column=0, padx=PAD, pady=PAD)
    tk.Button(nav, text="Exit", font=DEFAULT_FONT, width=22, command=root.quit).grid(row=7, column=0, padx=PAD, pady=PAD)

# --- Patient Management Screen ---
def show_patient_management_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Patient Management", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)
    # Add Patient
    tk.Label(frame, text="Full Name:", font=DEFAULT_FONT).grid(row=1, column=0, sticky="e", pady=PAD)
    entry_name = tk.Entry(frame, font=DEFAULT_FONT)
    entry_name.grid(row=1, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Date of Birth (YYYY-MM-DD):", font=DEFAULT_FONT).grid(row=2, column=0, sticky="e", pady=PAD)
    entry_dob = tk.Entry(frame, font=DEFAULT_FONT)
    entry_dob.grid(row=2, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Email:", font=DEFAULT_FONT).grid(row=3, column=0, sticky="e", pady=PAD)
    entry_email = tk.Entry(frame, font=DEFAULT_FONT)
    entry_email.grid(row=3, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Phone:", font=DEFAULT_FONT).grid(row=4, column=0, sticky="e", pady=PAD)
    entry_phone = tk.Entry(frame, font=DEFAULT_FONT)
    entry_phone.grid(row=4, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Gender:", font=DEFAULT_FONT).grid(row=5, column=0, sticky="e", pady=PAD)
    gender_var = tk.StringVar(value="Male")
    tk.OptionMenu(frame, gender_var, "Male", "Female", "Other").grid(row=5, column=1, sticky="w", pady=PAD)
    def add_patient():
        try:
            name = entry_name.get().strip()
            dob = entry_dob.get().strip()
            email = entry_email.get().strip()
            phone = entry_phone.get().strip()
            gender = gender_var.get()
            if not name or not dob or not email or not phone:
                messagebox.showerror("Error", "All fields are required.")
                return
            # Validate DOB format
            date_pattern = r"^\d{4}-\d{2}-\d{2}$"
            if not re.match(date_pattern, dob):
                messagebox.showerror("Input Error", "Date of Birth must be in YYYY-MM-DD format.")
                return
            # Try to parse DOB
            try:
                dob_obj = datetime.strptime(dob, "%Y-%m-%d").date()
            except ValueError:
                messagebox.showerror("Input Error", "Invalid date format for Date of Birth. Use YYYY-MM-DD.")
                return
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("""
                INSERT INTO patients (patient_id, full_name, dob, email, phone, gender)
                VALUES (seq_patient_id.NEXTVAL, :1, TO_DATE(:2, 'YYYY-MM-DD'), :3, :4, :5)
            """, (name, dob, email, phone, gender))
            conn.commit()
            messagebox.showinfo("Success", "Patient added successfully.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="Add Patient", font=DEFAULT_FONT, command=add_patient).grid(row=6, column=0, columnspan=2, pady=PAD)
    # List Patients
    def list_patients():
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT patient_id, full_name, dob, email, phone, gender FROM patients ORDER BY patient_id")
            records = cur.fetchall()
            win = tk.Toplevel(root)
            win.title("Patients List")
            lb = tk.Listbox(win, font=DEFAULT_FONT, width=60)
            lb.pack(fill=tk.BOTH, expand=True, padx=PAD, pady=PAD)
            for row in records:
                # row = (patient_id, full_name, dob, email, phone, gender)
                dob_str = row[2].strftime('%Y-%m-%d') if hasattr(row[2], "strftime") else str(row[2])
                lb.insert(tk.END, f"Patient ID   : {row[0]}")
                lb.insert(tk.END, f"Full Name    : {row[1]}")
                lb.insert(tk.END, f"DOB          : {dob_str}")
                lb.insert(tk.END, f"Email        : {row[3]}")
                lb.insert(tk.END, f"Phone        : {row[4]}")
                lb.insert(tk.END, f"Gender       : {row[5]}")
                lb.insert(tk.END, "-"*31)
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="List Patients", font=DEFAULT_FONT, command=list_patients).grid(row=7, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=8, column=0, columnspan=2, pady=PAD)

# --- Doctor Management Screen ---
def show_doctor_management_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Doctor Management", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)
    # Add Doctor
    tk.Label(frame, text="Full Name:", font=DEFAULT_FONT).grid(row=1, column=0, sticky="e", pady=PAD)
    name_entry = tk.Entry(frame, font=DEFAULT_FONT)
    name_entry.grid(row=1, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Email:", font=DEFAULT_FONT).grid(row=2, column=0, sticky="e", pady=PAD)
    email_entry = tk.Entry(frame, font=DEFAULT_FONT)
    email_entry.grid(row=2, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Phone:", font=DEFAULT_FONT).grid(row=3, column=0, sticky="e", pady=PAD)
    phone_entry = tk.Entry(frame, font=DEFAULT_FONT)
    phone_entry.grid(row=3, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Specialty ID:", font=DEFAULT_FONT).grid(row=4, column=0, sticky="e", pady=PAD)
    specialty_id_entry = tk.Entry(frame, font=DEFAULT_FONT)
    specialty_id_entry.grid(row=4, column=1, sticky="w", pady=PAD)
    def add_doctor():
        try:
            name = name_entry.get().strip()
            email = email_entry.get().strip()
            phone = phone_entry.get().strip()
            specialty_id = specialty_id_entry.get().strip()
            if not name or not email or not phone or not specialty_id:
                messagebox.showerror("Error", "All fields are required.")
                return
            conn = get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO doctors (
                    doctor_id, full_name, email, phone, specialty_id
                ) VALUES (
                    seq_doctor_id.NEXTVAL, :1, :2, :3, :4
                )
            """, (name_entry.get(), email_entry.get(), phone_entry.get(), specialty_id_entry.get()))
            conn.commit()
            messagebox.showinfo("Success", "Doctor added successfully.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="Add Doctor", font=DEFAULT_FONT, command=add_doctor).grid(row=5, column=0, columnspan=2, pady=PAD)
    # List Doctors
    def list_doctors():
        try:
            conn = get_connection()
            cur = conn.cursor()
            # Fetch doctor info, including specialty_id if present
            cur.execute("SELECT doctor_id, full_name, email, phone, specialty_id FROM doctors ORDER BY doctor_id")
            records = cur.fetchall()
            win = tk.Toplevel(root)
            win.title("Doctors List")
            # Use a Text widget for formatted columns
            text = tk.Text(win, font=("Courier New", 11), width=100, height=25)
            text.pack(fill=tk.BOTH, expand=True, padx=PAD, pady=PAD)
            # Header
            text.insert(tk.END, "{:<10} {:<25} {:<25} {:<15} {:<15}\n".format(
                "ID", "Name", "Email", "Phone", "Specialty ID"))
            text.insert(tk.END, "-"*95 + "\n")
            for r in records:
                # doctor_id, full_name, email, phone, specialty_id
                text.insert(tk.END, "{:<10} {:<25} {:<25} {:<15} {:<15}\n".format(
                    r[0], r[1], r[2], r[3], r[4] if r[4] is not None else ""))
            text.config(state=tk.DISABLED)
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="List Doctors", font=DEFAULT_FONT, command=list_doctors).grid(row=6, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=7, column=0, columnspan=2, pady=PAD)

# --- Appointment Booking Screen ---
def show_appointment_booking_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Book Appointment", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)
    # Dropdowns for Patient and Doctor
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT patient_id, full_name FROM patients ORDER BY patient_id")
        patients = cur.fetchall()
        cur.execute("SELECT doctor_id, full_name FROM doctors ORDER BY doctor_id")
        doctors = cur.fetchall()
    except Exception as e:
        messagebox.showerror("Error", f"Error fetching patients/doctors: {e}")
        patients, doctors = [], []
    patient_var = tk.StringVar()
    doctor_var = tk.StringVar()
    tk.Label(frame, text="Patient:", font=DEFAULT_FONT).grid(row=1, column=0, sticky="e", pady=PAD)
    patient_options = [f"{p[0]} - {p[1]}" for p in patients] if patients else []
    patient_var.set(patient_options[0] if patient_options else "")
    tk.OptionMenu(frame, patient_var, *patient_options).grid(row=1, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Doctor:", font=DEFAULT_FONT).grid(row=2, column=0, sticky="e", pady=PAD)
    doctor_options = [f"{d[0]} - {d[1]}" for d in doctors] if doctors else []
    doctor_var.set(doctor_options[0] if doctor_options else "")
    tk.OptionMenu(frame, doctor_var, *doctor_options).grid(row=2, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Date (YYYY-MM-DD):", font=DEFAULT_FONT).grid(row=3, column=0, sticky="e", pady=PAD)
    entry_date = tk.Entry(frame, font=DEFAULT_FONT)
    entry_date.grid(row=3, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Time (e.g., 02:00 PM):", font=DEFAULT_FONT).grid(row=4, column=0, sticky="e", pady=PAD)
    entry_time = tk.Entry(frame, font=DEFAULT_FONT)
    entry_time.grid(row=4, column=1, sticky="w", pady=PAD)
    tk.Label(frame, text="Reason:", font=DEFAULT_FONT).grid(row=5, column=0, sticky="e", pady=PAD)
    entry_reason = tk.Entry(frame, font=DEFAULT_FONT)
    entry_reason.grid(row=5, column=1, sticky="w", pady=PAD)
    def book_appointment_action():
        try:
            pid = int(patient_var.get().split(" - ")[0])
            did = int(doctor_var.get().split(" - ")[0])
            date_str = entry_date.get().strip()
            time_val = entry_time.get().strip()
            reason = entry_reason.get().strip()
            date_pattern = r"^\d{4}-\d{2}-\d{2}$"
            if not re.match(date_pattern, date_str):
                messagebox.showerror("Input Error", "Date must be in YYYY-MM-DD format.")
                return
            date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
            # Conflict checking: check if doctor has an appointment at that date/time
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("""SELECT COUNT(*) FROM appointments WHERE doctor_id=:1 AND appointment_date=:2 AND appointment_time=:3 AND status='Scheduled'""", [did, date_obj, time_val])
            conflict = cur.fetchone()[0]
            if conflict:
                messagebox.showerror("Conflict", "Doctor already has an appointment at this date/time.")
                return
            cur.callproc("hospital_pkg.create_appointment", [pid, did, date_obj, time_val, reason])
            conn.commit()
            messagebox.showinfo("Success", "Appointment booked successfully.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="Book", font=DEFAULT_FONT, command=book_appointment_action).grid(row=6, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=7, column=0, columnspan=2, pady=PAD)


# --- Update Appointment Screen ---
def show_update_appointment_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()

    tk.Label(frame, text="Update Appointment", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)

    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT appointment_id FROM appointments WHERE status = 'Scheduled' ORDER BY appointment_id")
        appointment_ids = [str(row[0]) for row in cur.fetchall()]
    except Exception as e:
        messagebox.showerror("Error", f"Error fetching appointment IDs: {e}")
        return

    tk.Label(frame, text="Appointment ID:", font=DEFAULT_FONT).grid(row=1, column=0, sticky="e", pady=PAD)
    appointment_var = tk.StringVar()
    appointment_var.set(appointment_ids[0] if appointment_ids else "")
    tk.OptionMenu(frame, appointment_var, *appointment_ids).grid(row=1, column=1, sticky="w", pady=PAD)

    tk.Label(frame, text="New Reason:", font=DEFAULT_FONT).grid(row=2, column=0, sticky="e", pady=PAD)
    entry_reason = tk.Entry(frame, font=DEFAULT_FONT)
    entry_reason.grid(row=2, column=1, sticky="w", pady=PAD)

    tk.Label(frame, text="New Status:", font=DEFAULT_FONT).grid(row=3, column=0, sticky="e", pady=PAD)
    status_var = tk.StringVar()
    status_options = ["Scheduled", "Completed", "Cancelled"]
    status_var.set(status_options[0])
    tk.OptionMenu(frame, status_var, *status_options).grid(row=3, column=1, sticky="w", pady=PAD)

    def update_action():
        try:
            aid = int(appointment_var.get())
            reason = entry_reason.get().strip()
            status = status_var.get()
            conn = get_connection()
            cur = conn.cursor()
            result = cur.callfunc("update_appointment_fn", cx_Oracle.STRING, [aid, status, reason])
            conn.commit()
            messagebox.showinfo("Success", result)
        except Exception as e:
            messagebox.showerror("Error", str(e))
        finally:
            try:
                cur.close()
                conn.close()
            except:
                pass

    tk.Button(frame, text="Update", font=DEFAULT_FONT, command=update_action).grid(row=4, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=5, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Refresh", font=DEFAULT_FONT,
              command=lambda: show_update_appointment_screen()).grid(row=6, column=0, columnspan=2, pady=PAD)

# --- Appointment View Screen ---
def show_appointment_view_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack(fill=tk.BOTH, expand=True)
    tk.Label(frame, text="Appointments", font=("Segoe UI", 16, "bold")).pack(pady=PAD)
    filter_var = tk.StringVar(value="All")
    filter_options = ["All", "Scheduled", "Completed", "Cancelled"]
    filter_menu = tk.OptionMenu(frame, filter_var, *filter_options)
    filter_menu.pack(pady=PAD)
    listbox = tk.Listbox(frame, font=DEFAULT_FONT, width=100)
    listbox.pack(fill=tk.BOTH, expand=True, padx=PAD, pady=PAD)
    def refresh_view():
        listbox.delete(0, tk.END)
        try:
            conn = get_connection()
            cur = conn.cursor()
            status = filter_var.get()
            if status == "All":
                cur.execute("""
                    SELECT a.appointment_id, p.full_name, d.full_name, a.appointment_date, a.appointment_time, a.status
                    FROM appointments a
                    JOIN patients p ON a.patient_id = p.patient_id
                    JOIN doctors d ON a.doctor_id = d.doctor_id
                    ORDER BY a.appointment_date
                """)
            else:
                cur.execute("""
                    SELECT a.appointment_id, p.full_name, d.full_name, a.appointment_date, a.appointment_time, a.status
                    FROM appointments a
                    JOIN patients p ON a.patient_id = p.patient_id
                    JOIN doctors d ON a.doctor_id = d.doctor_id
                    WHERE a.status = :1
                    ORDER BY a.appointment_date
                """, [status])
            records = cur.fetchall()
            if not records:
                listbox.insert(tk.END, "No appointments found.")
            else:
                for r in records:
                    listbox.insert(tk.END, f"Appointment ID: {r[0]}")
                    listbox.insert(tk.END, f"Patient: {r[1]}")
                    listbox.insert(tk.END, f"Doctor: {r[2]}")
                    listbox.insert(tk.END, f"Date: {r[3].strftime('%Y-%m-%d') if isinstance(r[3], datetime) else r[3]}")
                    listbox.insert(tk.END, f"Time: {r[4]}")
                    listbox.insert(tk.END, f"Status: {r[5]}")
                    listbox.insert(tk.END, "-"*40)
        except Exception as e:
            listbox.insert(tk.END, f"Error: {str(e)}")
    filter_var.trace_add("write", lambda *args: refresh_view())
    tk.Button(frame, text="Refresh", font=DEFAULT_FONT, command=refresh_view).pack(pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).pack(pady=PAD)
    refresh_view()

# --- Cancel Appointment Screen ---
def show_cancel_appointment_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Cancel Appointment", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)
    tk.Label(frame, text="Appointment ID:", font=DEFAULT_FONT).grid(row=1, column=0, sticky="e", pady=PAD)
    entry_appt_id = tk.Entry(frame, font=DEFAULT_FONT)
    entry_appt_id.grid(row=1, column=1, sticky="w", pady=PAD)
    status_var = tk.StringVar(value="")
    status_label = tk.Label(frame, textvariable=status_var, font=DEFAULT_FONT)
    status_label.grid(row=2, column=0, columnspan=2, pady=PAD)
    def update_status():
        appt_id = entry_appt_id.get().strip()
        if not appt_id:
            status_var.set("")
            return
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT status FROM appointments WHERE appointment_id=:1", [appt_id])
            row = cur.fetchone()
            if row:
                status_var.set(f"Current status: {row[0]}")
            else:
                status_var.set("Appointment not found.")
        except Exception as e:
            status_var.set(f"Error: {e}")
    entry_appt_id.bind("<KeyRelease>", lambda e: update_status())
    def cancel_appt():
        appt_id = entry_appt_id.get().strip()
        if not appt_id.isdigit():
            messagebox.showerror("Error", "Enter a valid appointment ID.")
            return
        try:
            connection = get_connection()
            cursor = connection.cursor()
            cursor.callproc("hospital_pkg.cancel_appointment", [int(appt_id)])
            connection.commit()
            update_status()
            messagebox.showinfo("Success", "Appointment cancelled.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="Cancel Appointment", font=DEFAULT_FONT, command=cancel_appt).grid(row=3, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=4, column=0, columnspan=2, pady=PAD)

# --- Reports Screen ---
def show_reports_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Reports", font=("Segoe UI", 16, "bold")).pack(pady=PAD)
    lb = tk.Listbox(frame, font=DEFAULT_FONT, width=80)
    lb.pack(fill=tk.BOTH, expand=True, padx=PAD, pady=PAD)
    def doctor_appointment_counts():
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("""
                SELECT d.full_name, COUNT(a.appointment_id)
                FROM doctors d
                LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
                GROUP BY d.full_name
            """)
            rows = cur.fetchall()
            lb.delete(0, tk.END)
            lb.insert(tk.END, "Doctor Appointment Counts:")
            for row in rows:
                lb.insert(tk.END, f"{row[0]}: {row[1]}")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def appointment_counts_by_status():
        try:
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("""
                SELECT status, COUNT(*) FROM appointments GROUP BY status
            """)
            rows = cur.fetchall()
            lb.delete(0, tk.END)
            lb.insert(tk.END, "Appointment Counts by Status:")
            for row in rows:
                lb.insert(tk.END, f"{row[0]}: {row[1]}")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frame, text="Doctor Appointment Counts", font=DEFAULT_FONT, command=doctor_appointment_counts).pack(pady=PAD)
    tk.Button(frame, text="Appointment Counts by Status", font=DEFAULT_FONT, command=appointment_counts_by_status).pack(pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).pack(pady=PAD)

# --- Procedures/Functions Test Screen ---
def show_test_functions_screen():
    clear_root()
    frame = tk.Frame(root, padx=PAD, pady=PAD)
    frame.pack()
    tk.Label(frame, text="Procedures/Functions", font=("Segoe UI", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=PAD)
    # create_appointment
    tk.Button(frame, text="Test create_appointment", font=DEFAULT_FONT, command=test_create_appointment).grid(row=1, column=0, columnspan=2, pady=PAD)
    # cancel_appointment
    tk.Button(frame, text="Test cancel_appointment", font=DEFAULT_FONT, command=test_cancel_appointment).grid(row=2, column=0, columnspan=2, pady=PAD)
    # get_patient_fullname
    tk.Button(frame, text="Test get_patient_fullname", font=DEFAULT_FONT, command=test_get_patient_fullname).grid(row=3, column=0, columnspan=2, pady=PAD)
    # get_doctor_room
    tk.Button(frame, text="Test get_doctor_room", font=DEFAULT_FONT, command=test_get_doctor_room).grid(row=4, column=0, columnspan=2, pady=PAD)
    # get_doctor_appointment_count
    tk.Button(frame, text="Test get_doctor_appointment_count", font=DEFAULT_FONT, command=test_get_doctor_appointment_count).grid(row=5, column=0, columnspan=2, pady=PAD)
    # hospital_pkg package
    tk.Button(frame, text="Test hospital_pkg package", font=DEFAULT_FONT, command=test_hospital_pkg_package).grid(row=6, column=0, columnspan=2, pady=PAD)
    tk.Button(frame, text="Back", font=DEFAULT_FONT, command=show_welcome_screen).grid(row=7, column=0, columnspan=2, pady=PAD)

# --- Test function implementations ---
from tkinter import simpledialog
def test_create_appointment():
    try:
        pid = simpledialog.askinteger("create_appointment", "Patient ID:")
        did = simpledialog.askinteger("create_appointment", "Doctor ID:")
        date_str = simpledialog.askstring("create_appointment", "Date (YYYY-MM-DD):")
        time = simpledialog.askstring("create_appointment", "Time (e.g., 02:00 PM):")
        reason = simpledialog.askstring("create_appointment", "Reason:")
        if None in (pid, did, date_str, time, reason):
            return
        date_obj = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
        conn = get_connection()
        cur = conn.cursor()
        cur.callproc("create_appointment", [pid, did, date_obj, time.strip(), reason.strip()])
        conn.commit()
        messagebox.showinfo("Success", "Appointment created via procedure.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

def test_cancel_appointment():
    try:
        appt_id = simpledialog.askinteger("cancel_appointment", "Appointment ID:")
        if appt_id is None:
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.callproc("cancel_appointment", [appt_id])
        conn.commit()
        messagebox.showinfo("Success", "Appointment cancelled via procedure.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

def test_get_patient_fullname():
    try:
        pid = simpledialog.askinteger("get_patient_fullname", "Patient ID:")
        if pid is None:
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT get_patient_fullname(:1) FROM dual", [pid])
        fullname = cur.fetchone()[0]
        if fullname:
            messagebox.showinfo("Patient Fullname", f"Patient ID {pid} Fullname: {fullname}")
        else:
            messagebox.showinfo("Patient Fullname", "No patient found.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

def test_get_doctor_room():
    try:
        did = simpledialog.askinteger("get_doctor_room", "Doctor ID:")
        if did is None:
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT get_doctor_room(:1) FROM dual", [did])
        room = cur.fetchone()[0]
        if room:
            messagebox.showinfo("Doctor Room", f"Doctor ID {did} Room: {room}")
        else:
            messagebox.showinfo("Doctor Room", "No room information found.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

def test_get_doctor_appointment_count():
    try:
        did = simpledialog.askinteger("get_doctor_appointment_count", "Doctor ID:")
        if did is None:
            return
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT hospital_pkg.get_doctor_appointment_count(:1, SYSDATE) FROM dual", [did])
        count = cur.fetchone()[0]
        messagebox.showinfo("Doctor Appointment Count", f"Doctor ID {did} has {count} appointments.")
    except Exception as e:
        messagebox.showerror("Error", str(e))

def test_hospital_pkg_package():
    try:
        # Test several package procedures/functions
        win = tk.Toplevel(root)
        win.title("hospital_pkg Package")
        frm = tk.Frame(win, padx=PAD, pady=PAD)
        frm.pack()
        tk.Label(frm, text="Patient ID:", font=DEFAULT_FONT).grid(row=0, column=0)
        entry_pid = tk.Entry(frm, font=DEFAULT_FONT)
        entry_pid.grid(row=0, column=1)
        tk.Label(frm, text="Doctor ID:", font=DEFAULT_FONT).grid(row=1, column=0)
        entry_did = tk.Entry(frm, font=DEFAULT_FONT)
        entry_did.grid(row=1, column=1)
        tk.Label(frm, text="Appointment ID:", font=DEFAULT_FONT).grid(row=2, column=0)
        entry_aid = tk.Entry(frm, font=DEFAULT_FONT)
        entry_aid.grid(row=2, column=1)
        tk.Label(frm, text="Status:", font=DEFAULT_FONT).grid(row=3, column=0)
        entry_status = tk.Entry(frm, font=DEFAULT_FONT)
        entry_status.grid(row=3, column=1)
        def pkg_create_appointment():
            try:
                pid = int(entry_pid.get())
                did = int(entry_did.get())
                date_str = simpledialog.askstring("Create Appointment", "Enter Date (YYYY-MM-DD):", parent=win)
                time = simpledialog.askstring("Create Appointment", "Enter Time (e.g., 02:00 PM):", parent=win)
                reason = simpledialog.askstring("Create Appointment", "Enter Reason:", parent=win)
                if None in (date_str, time, reason):
                    return
                date_obj = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
                conn = get_connection()
                cur = conn.cursor()
                cur.callproc("hospital_pkg.create_appointment", [pid, did, date_obj, time.strip(), reason.strip()])
                conn.commit()
                messagebox.showinfo("Success", "Appointment created via hospital_pkg.")
            except Exception as e:
                messagebox.showerror("Error", str(e))
        def pkg_cancel_appointment():
            try:
                appt_id = int(entry_aid.get())
                conn = get_connection()
                cur = conn.cursor()
                cur.callproc("hospital_pkg.cancel_appointment", [appt_id])
                conn.commit()
                messagebox.showinfo("Success", "Appointment cancelled via hospital_pkg.")
            except Exception as e:
                messagebox.showerror("Error", str(e))
        def pkg_get_doctor_name():
            try:
                did = int(entry_did.get())
                conn = get_connection()
                cur = conn.cursor()
                cur.execute("SELECT hospital_pkg.get_doctor_name(:1) FROM dual", [did])
                name = cur.fetchone()[0]
                if name:
                    messagebox.showinfo("Doctor Name", f"Doctor ID {did}: {name}")
                else:
                    messagebox.showinfo("Doctor Name", "No doctor found.")
            except Exception as e:
                messagebox.showerror("Error", str(e))
        def pkg_get_patient_age():
            try:
                pid = int(entry_pid.get())
                conn = get_connection()
                cur = conn.cursor()
                cur.execute("SELECT hospital_pkg.get_patient_age(:1) FROM dual", [pid])
                age = cur.fetchone()[0]
                if age is not None:
                    messagebox.showinfo("Patient Age", f"Patient ID {pid} Age: {age}")
                else:
                    messagebox.showinfo("Patient Age", "No patient found.")
            except Exception as e:
                messagebox.showerror("Error", str(e))
        def pkg_count_appointments_by_status():
            try:
                status = entry_status.get()
                conn = get_connection()
                cur = conn.cursor()
                cur.execute("SELECT hospital_pkg.count_appointments_by_status(:1) FROM dual", [status])
                count = cur.fetchone()[0]
                messagebox.showinfo("Appointments Count", f"Appointments with status '{status}': {count}")
            except Exception as e:
                messagebox.showerror("Error", str(e))
        tk.Button(frm, text="create_appointment", font=DEFAULT_FONT, command=pkg_create_appointment).grid(row=0, column=2, padx=PAD, pady=PAD)
        tk.Button(frm, text="cancel_appointment", font=DEFAULT_FONT, command=pkg_cancel_appointment).grid(row=2, column=2, padx=PAD, pady=PAD)
        tk.Button(frm, text="get_doctor_name", font=DEFAULT_FONT, command=pkg_get_doctor_name).grid(row=1, column=2, padx=PAD, pady=PAD)
        tk.Button(frm, text="get_patient_age", font=DEFAULT_FONT, command=pkg_get_patient_age).grid(row=0, column=3, padx=PAD, pady=PAD)
        tk.Button(frm, text="count_appointments_by_status", font=DEFAULT_FONT, command=pkg_count_appointments_by_status).grid(row=3, column=2, padx=PAD, pady=PAD)
        tk.Button(frm, text="Close", font=DEFAULT_FONT, command=win.destroy).grid(row=4, column=0, columnspan=4, pady=PAD)
    except Exception as e:
        messagebox.showerror("Error", str(e))

# --- Start the GUI at Welcome Screen ---
show_welcome_screen()
root.mainloop()


def show_view_appointments_screen():
    # Show all appointments in a new window, with back button
    win = tk.Toplevel(root)
    win.title("All Appointments")

    # --- Filter dropdown ---
    filter_var = tk.StringVar(value="Scheduled")
    filter_options = ["All", "Scheduled", "Completed", "Cancelled"]
    filter_menu = tk.OptionMenu(win, filter_var, *filter_options)
    filter_menu.pack(pady=5)

    # --- Listbox with scrollbar ---
    listbox_frame = tk.Frame(win)
    listbox_frame.pack(fill=tk.BOTH, expand=True)
    scrollbar = tk.Scrollbar(listbox_frame)
    scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
    listbox = tk.Listbox(listbox_frame, yscrollcommand=scrollbar.set, width=100)
    listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
    scrollbar.config(command=listbox.yview)

    # --- Refresh function for filtering ---
    def refresh_view():
        listbox.delete(0, tk.END)
        try:
            conn = get_connection()
            cur = conn.cursor()
            status = filter_var.get()
            cur.execute("""
                SELECT a.appointment_id, p.full_name, d.full_name, a.appointment_date, a.appointment_time, a.status
                FROM appointments a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors d ON a.doctor_id = d.doctor_id
                WHERE (:1 = 'All' OR a.status = :1)
                ORDER BY a.appointment_date
            """, [status])
            records = cur.fetchall()
            if not records:
                listbox.insert(tk.END, "No appointments found.")
            else:
                for r in records:
                    listbox.insert(tk.END, f"Appointment ID: {r[0]}")
                    listbox.insert(tk.END, f"Patient: {r[1]}")
                    listbox.insert(tk.END, f"Doctor: {r[2]}")
                    listbox.insert(tk.END, f"Date: {r[3].strftime('%Y-%m-%d') if isinstance(r[3], datetime) else r[3]}")
                    listbox.insert(tk.END, f"Time: {r[4]}")
                    listbox.insert(tk.END, f"Status: {r[5]}")
                    listbox.insert(tk.END, "-"*40)
        except cx_Oracle.DatabaseError as e:
            listbox.insert(tk.END, f"Error: {str(e)}")

    # --- Refresh button ---
    tk.Button(win, text="Refresh", command=refresh_view).pack(pady=5)

    # --- Initial population of listbox ---
    refresh_view()

    tk.Button(win, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).pack(pady=10)


def show_doctor_info_screen():
    win = tk.Toplevel(root)
    win.title("Doctor Info")
    frm = tk.Frame(win, padx=10, pady=10)
    frm.pack()
    tk.Label(frm, text="Doctor ID:").grid(row=0, column=0)
    entry_doctor_id = tk.Entry(frm)
    entry_doctor_id.grid(row=0, column=1)
    def get_doctor_info_local():
        try:
            did = int(entry_doctor_id.get())
            if not isinstance(did, int):
                messagebox.showerror("Input Error", "Doctor ID must be a number.")
                return
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT full_name, email, phone FROM doctors WHERE doctor_id = :1", [did])
            doc = cur.fetchone()
            if doc:
                messagebox.showinfo("Doctor Info", f"Name: {doc[0]}\nEmail: {doc[1]}\nPhone: {doc[2]}")
            else:
                messagebox.showinfo("Doctor Info", "No doctor found.")
        except ValueError:
            messagebox.showerror("Input Error", "Doctor ID must be a number.")
        except cx_Oracle.DatabaseError as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frm, text="Get Doctor Info", command=get_doctor_info_local).grid(row=1, column=0, columnspan=2, pady=10)
    tk.Button(frm, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).grid(row=2, column=0, columnspan=2, pady=10)


def show_patient_info_screen():
    win = tk.Toplevel(root)
    win.title("Patient Info")
    frm = tk.Frame(win, padx=10, pady=10)
    frm.pack()
    tk.Label(frm, text="Patient ID:").grid(row=0, column=0)
    entry_patient_id = tk.Entry(frm)
    entry_patient_id.grid(row=0, column=1)
    def get_patient_info_local():
        try:
            pid = entry_patient_id.get()
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT full_name, email, phone, gender FROM patients WHERE patient_id = :1", [pid])
            pat = cur.fetchone()
            if pat:
                messagebox.showinfo("Patient Info", f"Name: {pat[0]}\nEmail: {pat[1]}\nPhone: {pat[2]}\nGender: {pat[3]}")
            else:
                messagebox.showinfo("Patient Info", "No patient found.")
        except cx_Oracle.DatabaseError as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frm, text="Get Patient Info", command=get_patient_info_local).grid(row=1, column=0, columnspan=2, pady=10)
    tk.Button(frm, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).grid(row=2, column=0, columnspan=2, pady=10)


def show_stored_procs_screen():
    win = tk.Toplevel(root)
    win.title("Stored Procedures")
    frm = tk.Frame(win, padx=10, pady=10)
    frm.pack()
    from tkinter import simpledialog
    def sp_create_appointment():
        try:
            pid = simpledialog.askinteger("Create Appointment", "Enter Patient ID:", parent=win)
            did = simpledialog.askinteger("Create Appointment", "Enter Doctor ID:", parent=win)
            date_str = simpledialog.askstring("Create Appointment", "Enter Date (YYYY-MM-DD):", parent=win)
            time = simpledialog.askstring("Create Appointment", "Enter Time (e.g., 02:00 PM):", parent=win)
            reason = simpledialog.askstring("Create Appointment", "Enter Reason:", parent=win)
            if None in (pid, did, date_str, time, reason):
                return
            date_obj = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
            conn = get_connection()
            cur = conn.cursor()
            cur.callproc("create_appointment", [pid, did, date_obj, time.strip(), reason.strip()])
            conn.commit()
            messagebox.showinfo("Success", "Appointment created via stored procedure.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def sp_cancel_appointment():
        try:
            appt_id = simpledialog.askinteger("Cancel Appointment", "Enter Appointment ID:", parent=win)
            if appt_id is None:
                return
            conn = get_connection()
            cur = conn.cursor()
            cur.callproc("cancel_appointment", [appt_id])
            conn.commit()
            messagebox.showinfo("Success", "Appointment cancelled via stored procedure.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def sp_get_patient_appointments():
        try:
            pid = simpledialog.askinteger("Get Patient Appointments", "Enter Patient ID:", parent=win)
            if pid is None:
                return
            conn = get_connection()
            cur = conn.cursor()
            # Use the correct SQL query to fetch patient appointments with room info
            cur.execute("""
                SELECT a.appointment_id, d.full_name, a.appointment_date, a.appointment_time, r.room_number AS room
                FROM appointments a
                JOIN doctors d ON a.doctor_id = d.doctor_id
                JOIN rooms r ON r.doctor_id = d.doctor_id
                WHERE a.patient_id = :patient_id
                ORDER BY a.appointment_date, a.appointment_time
            """, {"patient_id": pid})
            records = cur.fetchall()
            if not records:
                messagebox.showinfo("Patient Appointments", "No appointments found for this patient.")
                return
            win2 = tk.Toplevel(win)
            win2.title(f"Appointments for Patient ID {pid}")
            listbox = tk.Listbox(win2, width=80)
            listbox.pack(fill=tk.BOTH, expand=True)
            for row in records:
                # row = (appointment_id, doctor_name, appointment_date, appointment_time, room)
                listbox.insert(tk.END, f"Appt #{row[0]} | Doctor: {row[1]} | Date: {row[2]} {row[3]} | Room: {row[4]}")
            tk.Button(win2, text="Close", command=win2.destroy).pack(pady=5)
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frm, text="create_appointment", command=sp_create_appointment).grid(row=0, column=0, padx=5, pady=5)
    tk.Button(frm, text="cancel_appointment", command=sp_cancel_appointment).grid(row=0, column=1, padx=5, pady=5)
    tk.Button(frm, text="get_patient_appointments", command=sp_get_patient_appointments).grid(row=0, column=2, padx=5, pady=5)
    tk.Button(frm, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).grid(row=1, column=0, columnspan=3, pady=15)


def show_functions_screen():
    win = tk.Toplevel(root)
    win.title("Functions")
    frm = tk.Frame(win, padx=10, pady=10)
    frm.pack()
    tk.Label(frm, text="Doctor ID:").grid(row=0, column=0)
    entry_func_doctor_id = tk.Entry(frm)
    entry_func_doctor_id.grid(row=0, column=1)
    tk.Label(frm, text="Patient ID:").grid(row=1, column=0)
    entry_func_patient_id = tk.Entry(frm)
    entry_func_patient_id.grid(row=1, column=1)
    def func_get_doctor_appointment_count():
        try:
            did = int(entry_func_doctor_id.get())
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT hospital_pkg.get_doctor_appointment_count(:1, SYSDATE) FROM dual", [did])
            count = cur.fetchone()[0]
            messagebox.showinfo("Doctor Appointment Count", f"Doctor ID {did} has {count} appointments.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def func_get_patient_fullname():
        try:
            pid = entry_func_patient_id.get()
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT get_patient_fullname(:1) FROM dual", [pid])
            fullname = cur.fetchone()[0]
            if fullname:
                messagebox.showinfo("Patient Fullname", f"Patient ID {pid} Fullname: {fullname}")
            else:
                messagebox.showinfo("Patient Fullname", "No patient found.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def func_get_doctor_room():
        try:
            did = int(entry_func_doctor_id.get())
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT get_doctor_room(:1) FROM dual", [did])
            room = cur.fetchone()[0]
            if room:
                messagebox.showinfo("Doctor Room", f"Doctor ID {did} Room: {room}")
            else:
                messagebox.showinfo("Doctor Room", "No room information found.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frm, text="get_doctor_appointment_count", command=func_get_doctor_appointment_count).grid(row=0, column=2, padx=5, pady=5)
    tk.Button(frm, text="get_patient_fullname", command=func_get_patient_fullname).grid(row=1, column=2, padx=5, pady=5)
    tk.Button(frm, text="get_doctor_room", command=func_get_doctor_room).grid(row=2, column=2, padx=5, pady=5)
    tk.Button(frm, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).grid(row=3, column=0, columnspan=3, pady=10)


def show_package_screen():
    win = tk.Toplevel(root)
    win.title("Package Procedures/Functions (hospital_pkg)")
    frm = tk.Frame(win, padx=10, pady=10)
    frm.pack()
    tk.Label(frm, text="Patient ID:").grid(row=0, column=0)
    entry_pkg_patient_id = tk.Entry(frm)
    entry_pkg_patient_id.grid(row=0, column=1)
    tk.Label(frm, text="Doctor ID:").grid(row=1, column=0)
    entry_pkg_doctor_id = tk.Entry(frm)
    entry_pkg_doctor_id.grid(row=1, column=1)
    tk.Label(frm, text="Appointment ID:").grid(row=2, column=0)
    entry_pkg_appointment_id = tk.Entry(frm)
    entry_pkg_appointment_id.grid(row=2, column=1)
    tk.Label(frm, text="Status:").grid(row=3, column=0)
    entry_pkg_status = tk.Entry(frm)
    entry_pkg_status.grid(row=3, column=1)
    from tkinter import simpledialog
    def pkg_create_appointment():
        try:
            pid = int(entry_pkg_patient_id.get())
            did = int(entry_pkg_doctor_id.get())
            date_str = simpledialog.askstring("Create Appointment", "Enter Date (YYYY-MM-DD):", parent=win)
            time = simpledialog.askstring("Create Appointment", "Enter Time (e.g., 02:00 PM):", parent=win)
            reason = simpledialog.askstring("Create Appointment", "Enter Reason:", parent=win)
            if None in (date_str, time, reason):
                return
            date_obj = datetime.strptime(date_str.strip(), "%Y-%m-%d").date()
            conn = get_connection()
            cur = conn.cursor()
            cur.callproc("hospital_pkg.create_appointment", [pid, did, date_obj, time.strip(), reason.strip()])
            conn.commit()
            messagebox.showinfo("Success", "Appointment created via hospital_pkg.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def pkg_cancel_appointment():
        try:
            appt_id = int(entry_pkg_appointment_id.get())
            conn = get_connection()
            cur = conn.cursor()
            cur.callproc("hospital_pkg.cancel_appointment", [appt_id])
            conn.commit()
            messagebox.showinfo("Success", "Appointment cancelled via hospital_pkg.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def pkg_get_doctor_name():
        try:
            did = int(entry_pkg_doctor_id.get())
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT hospital_pkg.get_doctor_name(:1) FROM dual", [did])
            name = cur.fetchone()[0]
            if name:
                messagebox.showinfo("Doctor Name", f"Doctor ID {did}: {name}")
            else:
                messagebox.showinfo("Doctor Name", "No doctor found.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def pkg_get_patient_age():
        try:
            pid = int(entry_pkg_patient_id.get())
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT hospital_pkg.get_patient_age(:1) FROM dual", [pid])
            age = cur.fetchone()[0]
            if age is not None:
                messagebox.showinfo("Patient Age", f"Patient ID {pid} Age: {age}")
            else:
                messagebox.showinfo("Patient Age", "No patient found.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    def pkg_count_appointments_by_status():
        try:
            status = entry_pkg_status.get()
            conn = get_connection()
            cur = conn.cursor()
            cur.execute("SELECT hospital_pkg.count_appointments_by_status(:1) FROM dual", [status])
            count = cur.fetchone()[0]
            messagebox.showinfo("Appointments Count", f"Appointments with status '{status}': {count}")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    tk.Button(frm, text="create_appointment", command=pkg_create_appointment).grid(row=0, column=2, padx=5, pady=5)
    tk.Button(frm, text="cancel_appointment", command=pkg_cancel_appointment).grid(row=2, column=2, padx=5, pady=5)
    tk.Button(frm, text="get_doctor_name", command=pkg_get_doctor_name).grid(row=1, column=2, padx=5, pady=5)
    tk.Button(frm, text="get_patient_age", command=pkg_get_patient_age).grid(row=0, column=3, padx=5, pady=5)
    tk.Button(frm, text="count_appointments_by_status", command=pkg_count_appointments_by_status).grid(row=3, column=2, padx=5, pady=5)
    tk.Button(frm, text="Back to Main Menu", command=lambda: [win.destroy(), root.deiconify()]).grid(row=4, column=0, columnspan=4, pady=15)



def show_main_menu():
    clear_root()
    tk.Label(root, text="Welcome to Hospital System", font=("Arial", 16, "bold")).pack(pady=20)
    book_btn = tk.Button(root, text="Create Appointment", width=30, command=show_appointment_booking_screen)
    book_btn.pack(pady=5)
    update_btn = tk.Button(root, text="Update Appointment", width=30, command=show_update_appointment_screen)
    update_btn.pack(pady=5)
    tk.Button(root, text="Cancel Appointment", width=30, command=show_cancel_appointment_screen).pack(pady=5)
    tk.Button(root, text="View Appointments", width=30, command=show_appointment_view_screen).pack(pady=5)
    tk.Button(root, text="Exit", width=30, command=root.quit).pack(pady=20)

