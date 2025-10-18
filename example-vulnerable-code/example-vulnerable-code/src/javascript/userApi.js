const mysql = require('mysql');
const crypto = require('crypto');
const fs = require('fs');

/**
 * User API with multiple security and performance issues
 * FOR TESTING PURPOSES ONLY - DO NOT USE IN PRODUCTION
 */
class UserApi {
    constructor() {
        // ISSUE: Hardcoded database credentials (Security - CRITICAL)
        this.dbConfig = {
            host: 'localhost',
            user: 'admin',
            password: 'secretpass123',
            database: 'users'
        };

        // ISSUE: No connection pooling (Performance - HIGH)
        // Creating new connection for each query
    }

    // ISSUE: SQL Injection vulnerability (Security - CRITICAL)
    async getUserById(userId) {
        const connection = mysql.createConnection(this.dbConfig);

        // BAD: String concatenation in query
        const query = `SELECT * FROM users WHERE id = ${userId}`;

        return new Promise((resolve, reject) => {
            connection.query(query, (error, results) => {
                if (error) {
                    // ISSUE: Error details exposed (Security - MEDIUM)
                    reject(error);
                } else {
                    resolve(results[0]);
                }
                // ISSUE: Connection not properly closed (Resource leak)
                connection.end();
            });
        });
    }

    // ISSUE: XSS vulnerability (Security - HIGH)
    renderUserProfile(user) {
        // BAD: Direct HTML injection without sanitization
        return `
            <div class="profile">
                <h1>${user.name}</h1>
                <p>${user.bio}</p>
                <script>${user.customScript}</script>
            </div>
        `;
    }

    // ISSUE: N+1 Query Problem (Performance - CRITICAL)
    async getAllUsersWithPosts() {
        const connection = mysql.createConnection(this.dbConfig);

        // Get all users first
        const users = await this.query(connection, 'SELECT * FROM users');

        // ISSUE: Loop with async operations not parallelized (Performance - HIGH)
        for (const user of users) {
            // N+1: One query per user
            const posts = await this.query(
                connection,
                `SELECT * FROM posts WHERE user_id = ${user.id}`
            );
            user.posts = posts;
        }

        connection.end();
        return users;
    }

    // ISSUE: No authentication check (Security - CRITICAL)
    async deleteUser(req, res) {
        const userId = req.params.id;

        // No check if user is authorized to delete
        const connection = mysql.createConnection(this.dbConfig);

        // ISSUE: No validation (API Design - HIGH)
        const query = `DELETE FROM users WHERE id = ${userId}`;

        connection.query(query, (error, results) => {
            if (error) {
                // ISSUE: No proper error handling (Observability - HIGH)
                console.log(error);
                res.status(500).send('Error');
            } else {
                res.send('User deleted');
            }
        });

        // ISSUE: No logging of who deleted what (Observability - HIGH)
    }

    // ISSUE: Unhandled Promise rejection (Concurrency - HIGH)
    async processUserBatch(userIds) {
        const promises = userIds.map(async (userId) => {
            // This can fail but error is not handled
            const user = await this.getUserById(userId);
            await this.sendNotification(user);
            return user;
        });

        // ISSUE: No error handling for Promise.all
        return Promise.all(promises);
    }

    // ISSUE: Synchronous file operations blocking event loop (Performance - HIGH)
    saveUserAvatar(userId, avatarData) {
        const filename = `/uploads/avatar_${userId}.jpg`;

        // BAD: Synchronous file write blocks everything
        fs.writeFileSync(filename, avatarData);

        // ISSUE: Path traversal vulnerability (Security - HIGH)
        // userId could be "../../../etc/passwd"

        return filename;
    }

    // ISSUE: No timeout on external API calls (Resilience - HIGH)
    async fetchUserDataFromExternalApi(userId) {
        const fetch = require('node-fetch');

        // No timeout specified
        const response = await fetch(`https://api.external.com/users/${userId}`);

        // ISSUE: No retry logic (Resilience - MEDIUM)
        // ISSUE: No circuit breaker (Resilience - MEDIUM)

        return response.json();
    }

    // ISSUE: Weak password hashing (Security - CRITICAL)
    hashPassword(password) {
        // BAD: Using SHA1 for password hashing
        return crypto.createHash('sha1').update(password).digest('hex');
    }

    // ISSUE: Race condition (Concurrency - HIGH)
    async incrementUserPoints(userId, points) {
        const connection = mysql.createConnection(this.dbConfig);

        // Read
        const user = await this.query(
            connection,
            `SELECT points FROM users WHERE id = ${userId}`
        );

        // Modify (race condition here - another request might update between read and write)
        const newPoints = user[0].points + points;

        // Write
        await this.query(
            connection,
            `UPDATE users SET points = ${newPoints} WHERE id = ${userId}`
        );

        connection.end();
        return newPoints;
    }

    // ISSUE: No input validation (API Design - HIGH)
    async createUser(userData) {
        const connection = mysql.createConnection(this.dbConfig);

        // No validation of email format, password strength, etc.
        const query = `
            INSERT INTO users (email, username, password, age)
            VALUES ('${userData.email}', '${userData.username}', '${userData.password}', ${userData.age})
        `;

        // ISSUE: Age could be negative or non-numeric

        return this.query(connection, query);
    }

    // ISSUE: Callback hell (Code Quality - MEDIUM)
    getUserWithDetails(userId, callback) {
        const connection = mysql.createConnection(this.dbConfig);

        connection.query(`SELECT * FROM users WHERE id = ${userId}`, (err, user) => {
            if (err) return callback(err);

            connection.query(`SELECT * FROM user_settings WHERE user_id = ${userId}`, (err, settings) => {
                if (err) return callback(err);

                connection.query(`SELECT * FROM user_preferences WHERE user_id = ${userId}`, (err, prefs) => {
                    if (err) return callback(err);

                    callback(null, {
                        user: user[0],
                        settings: settings[0],
                        preferences: prefs[0]
                    });
                });
            });
        });
    }

    // Helper function
    query(connection, sql) {
        return new Promise((resolve, reject) => {
            connection.query(sql, (error, results) => {
                if (error) reject(error);
                else resolve(results);
            });
        });
    }
}

module.exports = UserApi;