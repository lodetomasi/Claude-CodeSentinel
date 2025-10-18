import mysql.connector
import hashlib
import pickle
import os
import time
from threading import Thread

class UserService:
    """
    User service with multiple security and performance issues
    FOR TESTING PURPOSES ONLY - DO NOT USE IN PRODUCTION
    """

    def __init__(self):
        # ISSUE: Hardcoded database credentials (Security - CRITICAL)
        self.db_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'admin123',  # Hardcoded password
            'database': 'users_db'
        }

        # ISSUE: Shared mutable state without synchronization (Concurrency - HIGH)
        self.user_cache = {}
        self.request_count = 0

    def get_user_by_email(self, email):
        # ISSUE: SQL Injection vulnerability (Security - CRITICAL)
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        # BAD: String formatting in SQL query
        query = f"SELECT * FROM users WHERE email = '{email}'"
        cursor.execute(query)

        result = cursor.fetchone()

        # ISSUE: Resource leak - connection not in try-finally (Concurrency - HIGH)
        conn.close()

        return result

    def authenticate_user(self, username, password):
        # ISSUE: Weak hashing algorithm MD5 (Security - HIGH)
        password_hash = hashlib.md5(password.encode()).hexdigest()

        # ISSUE: SQL Injection again
        query = f"SELECT * FROM users WHERE username='{username}' AND password='{password_hash}'"

        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()
        cursor.execute(query)

        user = cursor.fetchone()
        conn.close()

        # ISSUE: No logging of authentication attempts (Observability - MEDIUM)

        return user is not None

    def get_all_users_with_orders(self):
        # ISSUE: N+1 Query Problem (Performance - CRITICAL)
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        # Get all users
        cursor.execute("SELECT id, email FROM users")
        users = cursor.fetchall()

        result = []
        for user in users:
            user_dict = {'id': user[0], 'email': user[1]}

            # ISSUE: N+1 - One query per user
            cursor.execute(f"SELECT * FROM orders WHERE user_id = {user[0]}")
            orders = cursor.fetchall()
            user_dict['orders'] = orders

            result.append(user_dict)

        conn.close()
        return result

    def process_user_data(self, serialized_data):
        # ISSUE: Insecure deserialization (Security - CRITICAL)
        user_data = pickle.loads(serialized_data)

        # Process the data
        self.save_user(user_data)

        return user_data

    def save_user(self, user_data):
        # ISSUE: No input validation (API Design - HIGH)
        # ISSUE: No transaction (Data Integrity - HIGH)
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        # ISSUE: Command injection vulnerability (Security - CRITICAL)
        if 'avatar_path' in user_data:
            os.system(f"cp {user_data['avatar_path']} /uploads/")

        # Insert user
        query = f"""
            INSERT INTO users (email, username, password)
            VALUES ('{user_data['email']}', '{user_data['username']}', '{user_data['password']}')
        """
        cursor.execute(query)

        # ISSUE: No commit called - data might not be saved
        conn.close()

    def increment_counter(self):
        # ISSUE: Race condition (Concurrency - HIGH)
        # Multiple threads can read-modify-write simultaneously
        self.request_count = self.request_count + 1
        return self.request_count

    def send_email_to_users(self, user_ids):
        # ISSUE: No timeout on external calls (Resilience - HIGH)
        # ISSUE: Synchronous blocking operation (Performance - MEDIUM)
        for user_id in user_ids:
            # Get user email
            conn = mysql.connector.connect(**self.db_config)
            cursor = conn.cursor()
            cursor.execute(f"SELECT email FROM users WHERE id = {user_id}")
            email = cursor.fetchone()[0]

            # Simulate sending email - blocking call
            time.sleep(1)  # This blocks the entire thread

            # ISSUE: Connection created in loop (Performance - HIGH)
            conn.close()

    def update_user_password(self, user_id, new_password):
        try:
            conn = mysql.connector.connect(**self.db_config)
            cursor = conn.cursor()

            # ISSUE: Storing password in plain text (Security - CRITICAL)
            query = f"UPDATE users SET password = '{new_password}' WHERE id = {user_id}"
            cursor.execute(query)

            conn.commit()
            conn.close()
        except Exception as e:
            # ISSUE: Silent failure - exception swallowed (Observability - HIGH)
            pass  # Error is completely ignored

    def get_user_profile(self, user_id):
        # ISSUE: No caching for frequently accessed data (Performance - MEDIUM)
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        # Get user
        cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
        user = cursor.fetchone()

        # Get user settings - separate query
        cursor.execute(f"SELECT * FROM user_settings WHERE user_id = {user_id}")
        settings = cursor.fetchone()

        # Get user preferences - another separate query
        cursor.execute(f"SELECT * FROM user_preferences WHERE user_id = {user_id}")
        preferences = cursor.fetchone()

        conn.close()

        # ISSUE: Multiple queries that could be joined (Performance - MEDIUM)
        return {
            'user': user,
            'settings': settings,
            'preferences': preferences
        }

    def delete_inactive_users(self):
        # ISSUE: No pagination - loading all users into memory (Performance - HIGH)
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()

        # Get ALL inactive users at once
        cursor.execute("SELECT * FROM users WHERE last_login < DATE_SUB(NOW(), INTERVAL 1 YEAR)")
        all_users = cursor.fetchall()  # Could be millions of records

        # ISSUE: No batch delete (Performance - HIGH)
        for user in all_users:
            cursor.execute(f"DELETE FROM users WHERE id = {user[0]}")

        conn.commit()
        conn.close()

        # ISSUE: No logging of deleted users (Observability - HIGH)

        return len(all_users)